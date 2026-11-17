# THE UNDERDOGS V24 – bản Java (NetBeans) – đồ án Lập trình mạng

Game co-op nhiều người chơi qua mạng, viết lại hoàn toàn từ bản Python/pygame V23 sang **Java (Swing + java.net)**.
Mô hình **Client – Server**, giao thức **TCP** (+ **UDP** để tự dò server trong LAN), tối đa **10 người/phòng**, 10 nhân vật, 9 màn.

---
## 1. Mở trong NetBeans
1. NetBeans → **File → Open Project…** → chọn thư mục `CroakSquad` (biểu tượng cốc cà phê).
   - Project dạng Ant ("Java Application"), JDK 8 trở lên. File `nbproject/build-impl.xml` sẽ được NetBeans tự sinh khi mở.
   - Nếu NetBeans báo lỗi project: tạo *New Project → Java Application* tên `CroakSquad`, xoá `Main.java` mẫu, rồi chép thư mục `src` (có cả `assets`) của gói này đè vào.
2. Trên thanh công cụ có ô chọn cấu hình (đang là `<default config>` = **Client**). Chọn **Server** để chạy server, **Client** để chạy game.
   Hoặc chuột phải file `ServerMain.java` / `ClientMain.java` → **Run File** (Shift+F6).
3. Chơi qua VPS: client đã mặc định kết nối `103.249.117.201:48440` (cổng public NAT) → cổng TCP `80` trên VPS. Máy 1 bấm **TẠO PHÒNG**, máy 2 nhập mã phòng → **VÀO PHÒNG** → cả hai **SẴN SÀNG** → chủ phòng **BẮT ĐẦU CHƠI**.
   Chơi thử localhost thì sửa `DEFAULT_SERVER` trong `Settings.java` thành `127.0.0.1:80` rồi build lại.
4. **Clean and Build** (Shift+F11) tạo `dist/CroakSquad.jar`. (Đã có sẵn jar trong gói này.)

Không dùng NetBeans: chạy `RUN_SERVER.bat` và `RUN_CLIENT.bat` (Windows) hoặc `run_server.sh` / `run_client.sh` (Linux/Mac). `BUILD.bat` / `build.sh` biên dịch lại bằng `javac`.

Server không giao diện (VPS Linux): `java -cp CroakSquad.jar croaksquad.server.ServerMain --nogui [cổng]`.
Chơi qua VPS: client mặc định dùng `103.249.117.201:48440`; NAT trên nhà cung cấp chuyển tiếp cổng public `48440` vào cổng TCP nội bộ `80` của VPS. Server bind TCP `80`; UDP `5057` chỉ dùng cho dò server LAN. Cổng `33911 → 3389` là Remote Desktop do hệ thống quản lý, không dùng cho game. Địa chỉ IP được lưu nội bộ và ẩn khỏi giao diện menu.

---
## 2. Cấu trúc mã nguồn
```
src/croaksquad/common/   Json.java        Đọc/ghi JSON tự viết (không cần thư viện ngoài)
                         Protocol.java    Hằng số dùng chung (cổng, giới hạn, tầm nắm...)
src/croaksquad/server/   GameServer.java  Server TCP đa luồng + UDP discovery (lõi môn học)
                         ServerFrame.java Cửa sổ quản lý: bật/tắt, log, danh sách phòng realtime
                         ServerMain.java  main (GUI hoặc --nogui)
src/croaksquad/client/   ClientMain.java  main + cửa sổ (F11 toàn màn hình)
                         GamePanel.java   Vòng lặp game, nhận phím/chuột, co giãn màn hình
                         Game.java        Logic: trạng thái, vật lý, xử lý thông điệp mạng, chat, LAN
                         Renderer.java    Toàn bộ phần vẽ
                         NetClient.java   Socket client: thread đọc + thread ghi + hàng đợi
                         Level.java       Sinh 9 màn (xác định, mọi client giống nhau), xu, chướng ngại
                         Assets.java      Nạp 180 khung hình nhân vật, cache co giãn
                         Sfx.java         Âm thanh sự kiện + nhạc nền WAV lấy từ thư mục assets/audio
                         Settings.java    Lưu tên/server/nhân vật/tiến trình/kỷ lục
src/assets/              180 PNG nhân vật
```

---
## 3. Kiến trúc mạng (phần để báo cáo)
- **TCP, TCP_NODELAY** bật. Mỗi thông điệp = **1 dòng JSON UTF-8 kết thúc `\n`** (line-delimited JSON).
- **Server**: `ServerSocket.accept()` → mỗi client **1 thread đọc**; mỗi client còn có **1 thread ghi + `BlockingQueue`** (client chậm không làm nghẽn cả phòng; gói `state` cũ bị bỏ khi hàng đợi ứ, client quá chậm bị ngắt). Dữ liệu phòng dùng chung được bảo vệ bằng một khoá (`synchronized`). `ScheduledExecutorService` xử lý việc hẹn giờ (nắm tay sau 0,46 s, chuyển màn sau 1,6 s).
- **Server là bên quyết định (authoritative)**: tạo/vào phòng, sẵn sàng/bắt đầu, nắm/ném (kiểm tra khoảng cách, chống hai người nắm cùng một người), nhặt xu (chống nhặt trùng), về đích và qua màn, bảng điểm.
- **Client**: thread đọc → `ConcurrentLinkedQueue` → vòng lặp game xử lý trên 1 thread (không cần khoá); thread ghi riêng. Kết nối chạy ở thread nền (không treo giao diện).
- **Đồng bộ vị trí**: mỗi client tự mô phỏng nhân vật của mình và báo lên ~25 gói/giây, server chuyển tiếp cho cả phòng; client làm mượt (nội suy) vị trí người khác. Chướng ngại chuyển động dùng đồng hồ xác định nên mọi người thấy giống nhau.
- **Heartbeat**: client `ping` mỗi 2 giây, server `pong` → hiển thị PING (ms); server ngắt client im lặng > 45 s.
- **Bảo vệ server**: giới hạn độ dài dòng (4 KB), làm sạch tên/chat, chống spam chat (0,4 s), giới hạn tần suất gói `state`, hello phải gửi trong 10 s.
- **Âm thanh**: `src/assets/audio/background.wav` phát lặp làm nhạc nền; `hut.wav` phát khi hút/nắm thành công; `die.wav` phát khi rơi/chết. Ba file MP3 người dùng cung cấp được chuyển sang WAV PCM 22.05 kHz mono để Java Sound phát trực tiếp, không cần thư viện MP3 ngoài.
- **UDP discovery**: server lắng nghe UDP **5057**; nút **TÌM LAN** (hoặc F5) của client broadcast `CROAKSQUAD_DISCOVER`, server trả `CROAKSQUAD_SERVER|cổng|tên máy|số phòng|số người|phiên bản` → tự điền địa chỉ server.

### Client → Server
| `type` | Trường | Ý nghĩa |
|---|---|---|
| (dòng đầu) | `mode`=`create`/`join`, `name`, `color`(0-9), `room` | Tạo/vào phòng |
| `ready` / `start` | `ready` / – | Sẵn sàng / chủ phòng bắt đầu (≥2 người, tất cả sẵn sàng) |
| `state` | `x`,`y`,`face` | Vị trí hiện tại |
| `grab` / `throw` | `target` / `power` 0-1 | Nắm đồng đội / ném người đang nâng |
| `coin` | `i` | Nhặt xu số i (server chống trùng) |
| `goal` | – | Đã về đích (cả đội về đích mới qua màn) |
| `reset_player` | `x`,`y`,`death` | Hồi sinh (R hoặc chết) |
| `chat` | `text` | Tin nhắn |
| `ping` | `t` | Đo độ trễ |

### Server → Client
`welcome`, `roster`, `ready`, `start`, `stage` (kèm thời gian màn trước), `state`, `action` (`reach`/`throw`), `grab`, `throw`, `reset_player`, `coin`, `scores`, `finish`, `chat`, `left`, `win` (bảng tổng kết), `pong`, `error`.

---
## 4. Điều khiển
| Phím | Online | Offline P1 | Offline P2 |
|---|---|---|---|
| Di chuyển | A/D hoặc ←/→ | A/D | ←/→ |
| Nhảy | SPACE | W | ↑ |
| Nắm tay | E | E hoặc F | ENTER |
| Giữ lấy lực → nhả để ném | giữ E → nhả E | giữ E/F | giữ ENTER |
| Hồi sinh / chơi lại màn | R | R | |
| Chat | ENTER hoặc T (ENTER gửi, ESC huỷ) | | |
| Bảng điểm | giữ TAB | giữ TAB | |
| Âm thanh | M | | |
| Toàn màn hình | F11 / Alt+Enter | | |

Đứng trên **nút áp lực** (hai bên cánh cửa) để mở cửa cho đồng đội; **bệ nảy** giúp bật cao; **gió** đẩy khi đang ở trên không; xu vàng nằm ở chỗ khó nên cần phối hợp mới lấy được.

---
## 5. So với V23 (Python)
**Tính năng mới**
- Viết lại sang Java, tách lớp rõ ràng (common / server / client; logic tách khỏi phần vẽ).
- **Server có giao diện** (bật/tắt, log, danh sách phòng/người chơi realtime) + chế độ console.
- **Chat** trong phòng chờ và trong game; thông báo vào/ra phòng.
- **Xu vàng** (nhặt đồng bộ qua server), **số lần chết**, **bảng điểm** (giữ TAB) và **màn tổng kết** cuối game có MVP; sau khi thắng quay về phòng chờ chơi lại.
- **Cả đội về đích mới qua màn** (bản cũ chỉ chủ phòng về đích là qua – người khác về đích không có tác dụng). Hiển thị "ĐÃ VỀ ĐÍCH", thời gian từng màn.
- **Thanh tiến độ** vị trí mọi người, checkpoint sáng lên khi đã chạm, bảng thông báo đầu màn/hoàn thành màn.
- **Tìm server LAN bằng UDP**, kết nối không chặn giao diện (có nút HỦY).
- **Âm thanh + nhạc nền** tổng hợp bằng code (M để tắt/bật).
- **Offline 2 người**: kỷ lục thời gian từng màn, camera bám cả hai người (không ai bị bỏ lại phía sau), R chơi lại đúng màn hiện tại, phải cùng về đích.
- Rời trận về menu (ESC) thay vì thoát cả chương trình; nhớ tên/server/nhân vật/âm thanh.

**Sửa lỗi so với V23**
- Gió trước đây gần như vô tác dụng (bị ghi đè mỗi khung hình) → nay đẩy thật khi ở trên không.
- Nhà cầm (carrier) chết/hồi sinh làm lệch trạng thái nắm → server huỷ liên kết nắm khi có người chết/rời phòng.
- Cánh cửa đóng đúng lúc đè lên người không còn "dịch chuyển" người lên đầu cửa.
- Phím R ở offline không còn quay về màn 1; núi nền không còn biến mất sau ~3600 px.

---
## 6. Lưu ý
- Đã kiểm thử tự động: 17 kiểm tra giao thức thô với server thật, một kịch bản tích hợp hai `Game` thật (tạo/vào phòng, chat, nắm–ném, xu, về đích, qua màn, chết, rời phòng, UDP), render ảnh kiểm tra giao diện/gameplay. **Chưa chạy bằng cửa sổ thật trên Windows/NetBeans** (môi trường kiểm thử không có màn hình) – nếu hình/âm thanh lệch, chỉnh trong `Renderer.character(...)`, `Game.step(...)`, `Sfx`.
- Hai người có thể chọn trùng nhân vật. Phòng đang chơi không cho người mới vào.
- Mã nguồn dùng cú pháp Java 8 để chạy được trên mọi phiên bản NetBeans/JDK từ 8 trở lên.
