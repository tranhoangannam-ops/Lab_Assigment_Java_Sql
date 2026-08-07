# TiTanGEAR — Tài liệu học & Ngân hàng câu hỏi vấn đáp

> Tài liệu này để **3 người trong nhóm học thuộc trước buổi bảo vệ**.
>
> Cách dùng: **Phần A cả 3 người đều phải nắm** — hội đồng hỏi bất kỳ ai cũng phải trả lời được.
> Từ Phần B trở đi mỗi người học sâu mảng của mình, nhưng vẫn nên đọc lướt mảng của 2 người kia
> để không đứng hình khi thầy hỏi chéo.
>
> Mỗi câu hỏi đều có **đáp án mẫu** và **chỗ code để mở ra chỉ cho hội đồng xem**. Mở đúng file
> lúc trả lời sẽ ăn điểm hơn nhiều so với chỉ nói suông.

---

## Phân vai

| | Mảng | Người phụ trách |
|---|---|---|
| **Người 1** | Bán hàng — luồng của khách từ lúc vào web tới lúc đơn được tạo | |
| **Người 2** | Kho và tiền — nhập/xuất kho, trạng thái đơn, báo cáo doanh thu | |
| **Người 3** | Khuyến mãi, quản trị, bảo mật | |

*(Điền tên vào cột bên phải.)*

---

# PHẦN A — NỀN TẢNG CHUNG (bắt buộc cả 3 người)

## A1. Dự án này là gì, dựng bằng gì

TiTanGEAR là website bán thiết bị ngoại vi máy tính (chuột, bàn phím, tai nghe gaming).
Có 3 loại người dùng: **khách hàng**, **thủ kho**, **quản trị viên**.

| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| Giao diện | JSP + JSTL + CSS thuần | Sinh HTML trả về trình duyệt |
| Điều khiển | Spring MVC 6 | Nhận request, gọi nghiệp vụ, chọn trang trả về |
| Nghiệp vụ | Spring Core (`@Service`) | Chứa toàn bộ luật kinh doanh |
| Truy cập dữ liệu | Spring Data JPA + Hibernate | Ánh xạ đối tượng Java ↔ bảng SQL |
| Cơ sở dữ liệu | SQL Server | Lưu dữ liệu + **3 trigger giữ tồn kho** |
| Bảo mật | Spring Security 6 | Đăng nhập, phân quyền, mã hóa mật khẩu, chống CSRF |
| Đóng gói | Maven → file `.war` chạy trên Tomcat 10 | |

**Điểm cần nhớ:** dự án **không dùng file XML nào** để cấu hình Spring. Toàn bộ cấu hình bằng
annotation Java, thông qua lớp `WebInitializer` — đây là kiểu cấu hình hiện đại, thay cho
`web.xml` kiểu cũ.

> **Câu hỏi hay bị hỏi ngay:** *"Sao không dùng Spring Boot cho nhanh?"*
> **Đáp:** Đề tài yêu cầu Spring MVC + JSP truyền thống để thấy rõ từng mảnh ghép của framework.
> Spring Boot tự cấu hình sẵn nhiều thứ, dùng thì nhanh nhưng nhóm sẽ không hiểu bên dưới nó
> làm gì. Ở đây nhóm tự khai `DispatcherServlet`, `ViewResolver`, `DataSource`, `EntityManagerFactory`
> nên nắm được toàn bộ vòng đời của một request.

---

## A2. Kiến trúc 3 tầng — và vì sao phải tách

```
Trình duyệt
    │  HTTP request
    ▼
┌─────────────────────────────────────────────┐
│  TẦNG ĐIỀU KHIỂN  (Controller)              │  ← nhận tham số, kiểm tra dạng dữ liệu,
│  com.titangear.controller                   │    chọn trang trả về. KHÔNG chứa luật kinh doanh.
└─────────────────────────────────────────────┘
    │  gọi
    ▼
┌─────────────────────────────────────────────┐
│  TẦNG NGHIỆP VỤ  (Service)                  │  ← toàn bộ luật kinh doanh, quản lý transaction
│  com.titangear.service                      │    (@Transactional)
└─────────────────────────────────────────────┘
    │  gọi
    ▼
┌─────────────────────────────────────────────┐
│  TẦNG DỮ LIỆU  (Repository / DAO)           │  ← Repository: CRUD qua JPA
│  com.titangear.repository  +  .dao          │    DAO: truy vấn SQL phức tạp cho báo cáo
└─────────────────────────────────────────────┘
    │
    ▼
  SQL Server
```

**Vì sao phải tách ba tầng như vậy:**

1. **Một luật kinh doanh chỉ được viết ở đúng một chỗ.** Ví dụ luật "không cho đặt quá 10 sản
   phẩm một đơn" nằm trong `OrderService`. Nếu để ở Controller thì mai mốt thêm đường đặt hàng
   mới (app điện thoại chẳng hạn) là luật đó bị bỏ sót.
2. **Đổi được từng tầng mà không đụng tầng khác.** Đổi JSP sang Thymeleaf chỉ sửa tầng View.
   Đổi SQL Server sang MySQL chỉ sửa tầng dữ liệu.
3. **Kiểm thử được.** Test viết cho `OrderService` chạy không cần bật Tomcat, không cần DB —
   xem `src/test/java/com/titangear/service/OrderServiceTest.java`. Nếu luật nằm trong Controller
   thì phải dựng cả web server mới test được.

**Hai lớp phụ trợ:**

| Package | Dùng làm gì |
|---|---|
| `model` | Các lớp Entity — mỗi lớp ứng với một bảng trong DB |
| `constant` | Hằng số dùng chung: `OrderStatus`, `TinhThanh` (34 tỉnh thành sau sáp nhập 2025) |
| `exception` | `LoiNghiepVu` — lớp lỗi riêng của nghiệp vụ (xem A6) |
| `config` | `AppConfig`, `SecurityConfig`, `WebInitializer`, `GlobalModelAdvice` |

---

## A3. Vòng đời một request — kể được mạch này là qua được nửa buổi bảo vệ

Ví dụ cụ thể: **khách bấm "Thêm vào giỏ"**.

```
1. Trình duyệt gửi:  POST /cart/add   (kèm productId, variantId, quantity, _csrf)
        │
2. Tomcat nhận, chuyển cho DispatcherServlet
   (đã khai trong WebInitializer, ánh xạ "/" nên nhận mọi đường dẫn)
        │
3. Chuỗi Filter của Spring Security chạy trước:
        ├── Đã đăng nhập chưa?          → chưa thì đá về /login
        ├── Token CSRF có hợp lệ không? → không thì trả 403
        │
4. DispatcherServlet tra bảng ánh xạ, tìm ra CartController.addToCart()
        │
5. Spring tự chuyển kiểu tham số: chuỗi "3" trong request → Integer 3
        │
6. Controller gọi cartService.addToCart(...)
        │
7. @Transactional MỞ transaction
        ├── kiểm số lượng > 0
        ├── kiểm sản phẩm tồn tại và còn bán
        ├── kiểm biến thể đúng thuộc sản phẩm đó
        ├── repository.save(...)  → Hibernate sinh câu INSERT/UPDATE
        └── transaction COMMIT (nếu ném lỗi thì ROLLBACK sạch)
        │
8. Controller trả chuỗi "redirect:/cart"
        │
9. Trình duyệt gọi tiếp GET /cart → ViewResolver ghép thành
   /WEB-INF/views/customer/cart.jsp → JSP sinh HTML → trả về
```

**Vì sao bước 8 lại redirect thay vì trả thẳng trang?**
Đây là mẫu **POST–Redirect–GET**. Nếu trả thẳng trang sau POST, khách bấm F5 là trình duyệt hỏi
"gửi lại dữ liệu?" và thêm sản phẩm lần nữa. Redirect xong thì URL trên thanh địa chỉ là GET,
F5 bao nhiêu lần cũng chỉ tải lại trang giỏ.

**Điểm dễ bị vặn:** *"Cấu hình Spring của em nằm ở đâu?"*
Mở `config/WebInitializer.java`. Lớp này kế thừa `AbstractAnnotationConfigDispatcherServletInitializer`,
Tomcat tự tìm và gọi lúc khởi động. Lưu ý riêng của dự án: **toàn bộ cấu hình nằm trong servlet
context**, hàm `getRootConfigClasses()` trả `null`. Hệ quả là mọi bean đều nằm chung một context —
điều này quan trọng khi cần thêm filter cấp servlet container.

---

## A4. Hibernate — Entity, LAZY và EAGER

### Entity là gì

Một lớp Java gắn `@Entity` ứng với một bảng. Ví dụ `model/Product.java` ↔ bảng `products`.
Hibernate lo việc dịch qua lại: gọi `product.getName()` là đọc cột `name`.

### LAZY và EAGER — câu này gần như chắc chắn bị hỏi

Khi nạp một `Product`, các danh sách con của nó (`variants`, `specs`) có nạp theo luôn không?

| | Nghĩa | Ưu | Nhược |
|---|---|---|---|
| **EAGER** | Nạp con **cùng lúc** với cha, trong một câu SQL có JOIN | Không bao giờ lỗi khi dùng ở JSP | Nạp thừa; nhiều danh sách EAGER cùng lúc gây **tích Descartes** |
| **LAZY** | Chỉ nạp cha; đụng tới con mới bắn thêm câu SQL | Nhẹ, nạp đúng cái cần | Nếu đụng tới con **sau khi transaction đã đóng** → `LazyInitializationException` |

**Tích Descartes là gì:** sản phẩm có 5 biến thể và 12 thông số kỹ thuật. JOIN cả hai bảng cùng
lúc, SQL Server trả về 5 × 12 = **60 dòng** cho một sản phẩm. Hibernate lọc lại còn đúng 5 + 12,
nhưng 60 dòng kia đã phải đọc từ đĩa và truyền qua mạng rồi. Nhân lên với danh sách nhiều sản
phẩm là chậm thấy rõ.

**Dự án này chọn thế nào và vì sao:**

- `Product.specs` và `Product.variants` để **EAGER**. Lý do: hai danh sách này được dùng ở
  *rất nhiều* trang JSP (chi tiết sản phẩm, so sánh, giỏ hàng, admin). JSP chạy **sau khi**
  transaction đã đóng, nên để LAZY là `LazyInitializationException` hàng loạt. Cách xử lý đúng
  bài là dùng "Open Session In View", nhưng do dự án đặt hết cấu hình trong servlet context nên
  filter đó không tra được bean — có ghi chú cảnh báo ngay trong `config/WebInitializer.java`.
- `CartItem.combo` và `CartItem.comboItem` để **LAZY**. Lý do: mỗi dòng giỏ hàng mà kéo theo cả
  combo và các món trong combo thì một giỏ 5 dòng sinh ra bảng kết quả khổng lồ.
- Chỗ nào cần con mà vẫn muốn nhanh thì dùng **`JOIN FETCH`** — lấy cha và con trong đúng một
  câu SQL do mình tự viết. Xem `repository/ComboRepository.java`.

### Lỗi N+1 — thuật ngữ hội đồng thích hỏi

Lấy danh sách 20 sản phẩm (1 câu SQL), rồi lặp qua từng sản phẩm hỏi giá khuyến mãi
(20 câu SQL nữa) → tổng 21 câu. Đó là N+1.

Dự án tránh bằng cách **gom một lượt**: xem `FlashSaleService.getEffectivePrices(List<Product>)` —
nhận cả danh sách, chạy **đúng một** câu truy vấn lấy toàn bộ khuyến mãi đang chạy, rồi đối chiếu
trong bộ nhớ. Tương tự có `ComboService.tinhGiaTungDong(cartItems)` và
`ReviewService.diemTheoDanhSach(ids)`.

---

## A5. Spring Security

### Xác thực và phân quyền — hai việc khác nhau

- **Xác thực (Authentication):** "Bạn là ai?" → kiểm email + mật khẩu.
- **Phân quyền (Authorization):** "Bạn được vào đâu?" → kiểm vai trò.

### Mật khẩu được lưu thế nào

**Không bao giờ lưu mật khẩu thật.** Dùng **BCrypt** — một hàm băm một chiều:

```java
// UserService.register
user.setPasswordHash(passwordEncoder.encode(user.getPasswordHash()));
```

Băm xong không đảo ngược lại được. Lúc đăng nhập, hệ thống băm mật khẩu vừa nhập rồi **so hai
chuỗi băm**, chứ không hề giải mã chuỗi trong DB.

BCrypt còn có **muối (salt)** ngẫu nhiên: hai người đặt mật khẩu giống hệt nhau vẫn ra hai chuỗi
băm khác nhau. Nhờ vậy kẻ trộm được DB không thể tra bảng dựng sẵn (rainbow table).

Mở `share.sql` phần bảng `users` chỉ ra cho hội đồng: cột `password_hash` toàn chuỗi
`$2a$10$...` — nhìn là biết BCrypt.

### CSRF — câu này rất dễ ăn điểm

**CSRF (Cross-Site Request Forgery)** là kiểu tấn công: kẻ xấu dụ người đang đăng nhập mở một
trang khác, trang đó âm thầm gửi request tới web của mình. Trình duyệt **tự động đính kèm cookie
phiên**, nên server tưởng chính chủ đang thao tác.

Cách chống: mỗi form đều mang một **token bí mật** do server phát, chỉ có trang thật của mình
mới biết. Trang của kẻ xấu không đoán được token.

```java
// SecurityConfig — CSRF bật cho toàn bộ site
.csrf(csrf -> csrf.ignoringRequestMatchers(
        new AntPathRequestMatcher("/api/payment/webhook")   // chỉ miễn trừ webhook thanh toán
));
```

**Điểm mấu chốt phải nhớ:** Spring Security **chỉ kiểm token trên POST/PUT/PATCH/DELETE**.
GET được miễn hoàn toàn, vì theo chuẩn HTTP thì GET là "chỉ đọc, không đổi gì".

Do đó **mọi thao tác làm thay đổi dữ liệu trong dự án đều phải là POST** — xóa, sửa, hủy, bật/tắt.
Chi tiết ở mục của Người 3 (B3.4).

### Phân quyền theo vai trò

Ba vai trò: `ADMIN`, `WAREHOUSE`, `CUSTOMER`.

```java
// SecurityConfig
.requestMatchers(new AntPathRequestMatcher("/warehouse/**")).hasAnyRole("ADMIN","WAREHOUSE")
.requestMatchers(new AntPathRequestMatcher("/admin/**")).hasRole("ADMIN")
```

Nguyên tắc: **ẩn nút ngoài giao diện không phải là bảo mật.** Ai cũng gõ được URL thẳng vào thanh
địa chỉ. Phải chặn ở tầng server. Ngoài `SecurityConfig`, các chỗ động tới dữ liệu của người khác
còn kiểm thêm quyền sở hữu — xem mục IDOR ở B1.5.

---

## A6. Ba quy ước riêng của dự án

### `LoiNghiepVu` — lớp lỗi của nghiệp vụ

`exception/LoiNghiepVu.java` kế thừa `RuntimeException`. Dùng cho mọi lỗi **do luật kinh doanh**,
ví dụ "không đủ hàng", "đơn này không hủy được nữa".

**Vì sao cần một lớp riêng thay vì `RuntimeException` chung:**

1. **Phân biệt được lỗi nghiệp vụ với lỗi kỹ thuật.** `LoiNghiepVu` là lỗi *dự đoán được*, câu
   thông báo viết sẵn bằng tiếng Việt để hiện thẳng cho người dùng. Còn `NullPointerException`
   hay lỗi mất kết nối DB là lỗi *ngoài dự tính* — không được hiện nguyên văn ra màn hình vì lộ
   cấu trúc hệ thống cho kẻ xấu.
2. **Controller bắt đúng loại cần bắt:**

```java
try {
    userService.deleteUser(id);
} catch (LoiNghiepVu e) {
    ra.addFlashAttribute("loi", e.getMessage());   // hiện thẳng cho admin
}
```
   Bắt `Exception` chung sẽ nuốt luôn cả lỗi lập trình, che mất bug thật.
3. Vì kế thừa `RuntimeException` (unchecked) nên `@Transactional` **tự động rollback** khi nó
   được ném ra — không phải khai báo gì thêm.

### `@Transactional` — mọi thứ hoặc xong hết, hoặc không gì cả

```java
@Transactional
public Order createOrder(Order order, List<CartItem> cartItems) { ... }
```

Tạo đơn gồm nhiều bước: ghi bảng `orders`, ghi nhiều dòng `order_items`, xóa giỏ hàng. Nếu bước
3 lỗi mà bước 1–2 đã ghi rồi thì DB còn lại một đơn hàng rỗng, giỏ hàng thì mất — dữ liệu hỏng.
`@Transactional` đảm bảo: có lỗi thì **toàn bộ** được hoàn tác.

### Trigger giữ tồn kho — chi tiết ở B2

Hai cột `products.stock_quantity` và `product_variants.stock` **không do Java ghi**. Chúng do
**trigger trong SQL Server** tự tính lại. Đây là điểm thiết kế quan trọng nhất của dự án, Người 2
phải giải thích được (xem B2.2).

---

## A7. Sơ đồ quan hệ dữ liệu (rút gọn)

```
                    ┌──────────┐
                    │  users   │────┐
                    └────┬─────┘    │
                         │          └──────────────┐
        ┌────────────────┼──────────────┐          │
        ▼                ▼              ▼          ▼
   ┌─────────┐     ┌──────────┐  ┌───────────┐  ┌──────────┐
   │  orders │     │cart_items│  │  reviews  │  │audit_log │
   └────┬────┘     └──────────┘  └───────────┘  └──────────┘
        │
        ▼
   ┌─────────────┐        ┌────────────┐        ┌──────────┐
   │ order_items │───────▶│  products  │◀───────│categories│
   └──────┬──────┘        └──────┬─────┘        └──────────┘
          │                      │
          │            ┌─────────┼──────────┬──────────────┐
          │            ▼         ▼          ▼              ▼
          │   ┌──────────────┐ ┌──────────────┐ ┌───────────────┐
          │   │product_specs │ │product_lines │ │product_variants│
          │   └──────────────┘ └──────────────┘ └───────┬───────┘
          │                                             │
          ▼                                             ▼
   ┌─────────────┐        trigger        ┌────────────────────┐
   │  stock_out  │◀────────────────────▶│      stock_in      │
   └─────────────┘                       └────────────────────┘

   Khuyến mãi:  combos ─ combo_items      flash_sales ─ flash_sale_items
                vouchers ─ voucher_usages
   Sau bán:     warranties ─ warranty_repairs
   Hệ thống:    system_settings,  restock_notifications
```

Tổng cộng **23 bảng**. File `share.sql` ở thư mục gốc dựng lại toàn bộ.

**Ba nhóm quan hệ đáng nói khi bảo vệ:**

1. `products` → `product_variants`: một sản phẩm nhiều màu. **Biến thể mới là đơn vị tồn kho thật.**
2. `products` → `product_lines`: mỗi phiên bản (Pro, Ultimate, Ultra Max) là **một sản phẩm riêng**,
   `product_lines` chỉ để nhóm chúng lại cho khách chuyển qua lại giữa các phiên bản.
3. `stock_in` → `stock_out`: xuất kho trỏ về **đúng lô nhập** đã lấy hàng ra, nhờ vậy truy được
   giá vốn thật của từng đơn (xem FIFO ở B2.3).

---

## A8. Câu hỏi chung — cả 3 người phải trả lời được

**Hỏi: Mô tả kiến trúc hệ thống của em.**
> Ba tầng. Controller nhận request và chọn trang trả về, không chứa luật kinh doanh. Service
> chứa toàn bộ luật và quản lý transaction. Repository/DAO nói chuyện với SQL Server.
> Tách như vậy để một luật chỉ viết một chỗ, đổi được từng tầng độc lập, và test được tầng
> nghiệp vụ mà không cần bật server.
> *(Mở cây thư mục `com.titangear` chỉ các package.)*

**Hỏi: Một request đi qua những đâu?**
> Trả lời theo mạch A3, kể tên `DispatcherServlet` → chuỗi Filter bảo mật → Controller → Service
> (`@Transactional`) → Repository → Hibernate sinh SQL → về `ViewResolver` → JSP.

**Hỏi: LAZY với EAGER khác nhau chỗ nào? Em dùng cái nào?**
> Trả lời theo A4. Nhấn đúng ba ý: tích Descartes khi nhiều danh sách EAGER; `LazyInitializationException`
> khi JSP đụng dữ liệu sau lúc transaction đóng; và `JOIN FETCH` là cách lấy được cả cha lẫn con
> trong một câu khi thật sự cần.

**Hỏi: Mật khẩu lưu thế nào?**
> BCrypt, băm một chiều, có muối ngẫu nhiên. Không giải mã, chỉ so chuỗi băm. *(Mở `share.sql`
> chỉ cột `password_hash` toàn `$2a$10$...`)*

**Hỏi: Nếu hai người cùng mua con hàng cuối cùng thì sao?**
> Có ba lớp. Thứ nhất, lúc tạo đơn tính `số đặt được = tồn kho − số đã nằm trong đơn chưa giao`,
> nên hàng đã có người đặt không bị bán lần hai. Thứ hai, `@Transactional` bảo đảm không để lại
> dữ liệu nửa vời. Thứ ba, lúc thủ kho duyệt xuất kho còn kiểm tồn lần nữa, thiếu là rollback
> toàn bộ. *(Chi tiết ở B1.4 và B2.3.)*

**Hỏi: Nhóm có viết test không?**
> Có, **60 test** cho tầng nghiệp vụ, dùng JUnit 5 + Mockito.
> *(Mở `src/test/java/com/titangear/service/`.)*
> Mockito tạo "đồ giả" cho Repository nên test chạy **không cần DB, không cần Tomcat**, chạy hết
> trong vài giây. Test tập trung vào các luật dễ sai: máy trạng thái đơn hàng, chống bán quá tồn
> kho, chống số lượng âm, chống duyệt xuất kho hai lần.

**Hỏi: Nhóm dùng Git thế nào?**
> Nhánh `main` giữ bản chạy được, nhánh `redesign/blueprint-ui` để phát triển. Commit theo từng
> nhóm tính năng, nội dung commit ghi bằng tiếng Việt mô tả rõ việc đã làm.

---

# PHẦN B1 — NGƯỜI 1: BÁN HÀNG

> **Phạm vi:** từ lúc khách mở web, xem sản phẩm, bỏ vào giỏ, đặt hàng, tới lúc xem lại đơn của
> mình. Đây là mảng hội đồng dễ bắt nhóm demo trực tiếp nhất.

## B1.1 Bản đồ code của Người 1

| File | Việc |
|---|---|
| `controller/ProductController` | Danh sách sản phẩm: lọc, sắp xếp, phân trang |
| `controller/ProductDetailController` | Chi tiết sản phẩm, đánh giá, đăng ký báo hàng về |
| `controller/SearchController` | Gợi ý tìm kiếm (`/api/search`) |
| `controller/CartController` | Giỏ hàng |
| `controller/CheckoutController` | Đặt hàng, chọn thanh toán, phí vận chuyển |
| `controller/MyOrdersController` | Đơn của tôi, hủy đơn |
| `service/CartService` | Luật của giỏ hàng |
| `service/OrderService.createOrder` | Luật tạo đơn |
| `service/ReviewService` | Đánh giá sản phẩm |

Bảng DB: `products`, `product_variants`, `product_lines`, `product_specs`, `categories`,
`cart_items`, `orders`, `order_items`, `reviews`.

---

## B1.2 Sản phẩm, phiên bản, biến thể — phân biệt cho rõ

Đây là chỗ hay bị hỏi vặn vì tên gọi dễ lẫn.

```
Dòng sản phẩm (product_lines):  "ATK F1"
      │
      ├── products #1   "Chuột ATK F1 Pro"          ← MỘT SẢN PHẨM RIÊNG, giá riêng
      │        └── product_variants: Đen, Trắng, Đỏ  ← chỉ khác MÀU
      │        └── product_specs: 12 dòng thông số
      │
      ├── products #15  "Chuột ATK F1 Pro Max"      ← SẢN PHẨM RIÊNG khác
      └── products #16  "Chuột ATK F1 Ultimate"     ← SẢN PHẨM RIÊNG khác
```

- **`product_lines`** chỉ để **nhóm** các phiên bản lại, cho khách bấm qua lại giữa Pro / Pro Max /
  Ultimate ngay trên trang chi tiết.
- **`products`** — mỗi phiên bản là một sản phẩm riêng, vì **giá khác nhau và thông số kỹ thuật
  khác nhau**.
- **`product_variants`** — chỉ khác nhau ở **màu sắc**. Và đây mới là **đơn vị tồn kho thật**.

> **Hỏi: Sao không để "phiên bản" cũng là biến thể luôn cho gọn?**
> **Đáp:** Vì phiên bản khác nhau ở **thông số kỹ thuật**, không chỉ ở giá. Bản Pro nặng 49g dùng
> cảm biến PAW3395, bản Ultimate nặng 43g dùng PAW3950. Nếu gộp làm biến thể thì bảng
> `product_specs` phải gắn vào biến thể, mà trang so sánh sản phẩm lại so theo sản phẩm — sẽ phải
> viết hai đường xử lý song song. Tách ra thành sản phẩm riêng thì mọi thứ dùng chung một đường.

---

## B1.3 Trang danh sách — lọc, sắp xếp, phân trang

Mở `controller/ProductController.java`, hàm `danhSach(...)`.

### Đoạn code này để làm gì

```java
// Lấy danh sách gốc, rồi lọc dần qua từng điều kiện
List<Product> products = tatCa;
if (keyword != null && !keyword.isEmpty()) { products = ...lọc theo tên... }
if (category != null)  { products = ...lọc theo danh mục... }
if (minPrice != null)  { products = ...lọc theo giá... }
...
```

Lọc **trong bộ nhớ Java** thay vì viết một câu SQL khổng lồ. Lý do: có tới **8 bộ lọc** có thể
bật/tắt độc lập (từ khóa, danh mục, khoảng giá, loại switch, trọng lượng, kết nối, còn hàng).
Ghép SQL động cho 8 điều kiện sẽ ra một hàm rối và dễ dính lỗi chèn SQL. Ở quy mô cửa hàng
(vài chục sản phẩm) thì lọc trong bộ nhớ nhanh hơn nhiều so với công sức bảo trì SQL động.

> **Nếu bị hỏi "shop có 100.000 sản phẩm thì sao?"** — trả lời thẳng: cách này sẽ không chịu nổi,
> lúc đó phải đẩy bộ lọc xuống DB và phân trang bằng `LIMIT/OFFSET`. Nhóm chọn cách hiện tại vì
> đúng với quy mô đề tài, và biết rõ giới hạn của nó ở đâu. **Trả lời kiểu này ăn điểm hơn nhiều
> so với cãi rằng cách của mình luôn tốt.**

### Đoạn code này để làm gì

```java
// PHẢI làm TRƯỚC mọi model.addAttribute("products", ...)
products = sapXep(products, sort);

int tong      = products.size();
int tongTrang = Math.max(1, (int) Math.ceil(tong / (double) MOI_TRANG));
int trang     = (page == null || page < 1) ? 1 : Math.min(page, tongTrang);
int tu        = (trang - 1) * MOI_TRANG;
products      = products.subList(tu, Math.min(tu + MOI_TRANG, tong));
```

Cắt danh sách lấy đúng phần của trang đang xem. Ba chi tiết cố ý:

- **`Math.max(1, ...)`** — giỏ rỗng thì vẫn tính là 1 trang, tránh chia cho 0 và tránh hiện
  "trang 1/0".
- **`Math.min(page, tongTrang)`** — khách gõ tay `?page=999` thì kẹp về trang cuối, không để
  `subList` ném `IndexOutOfBoundsException`.
- **Sắp xếp trước khi gán vào model.** Model giữ **tham chiếu** tới danh sách tại thời điểm gán;
  gán xong mới sắp xếp thì JSP vẫn nhận danh sách cũ, và ngoài giao diện sẽ thấy hiện tượng "bấm
  Giá tăng dần mà thứ tự không đổi".

---

## B1.4 Tạo đơn hàng — bốn hàng rào theo đúng thứ tự

Mở `service/OrderService.java`, hàm `createOrder`. Đây là hàm quan trọng nhất mảng của Người 1.

```java
@Transactional
public Order createOrder(Order order, List<CartItem> cartItems) {
    validateMaxQtyPerProduct(cartItems);      // ① số lượng có hợp lệ không
    validateConDangBan(cartItems);            // ② hàng còn bán không
    validateCodActiveOrderLimit(order);       // ③ có đang nợ quá nhiều đơn COD không
    if ("COD".equals(...) && requiresVnpay(...)) throw ...;   // ④ đơn to có được COD không
    for (CartItem ci : cartItems) { ...kiểm tồn kho... }      // ⑤ còn đủ hàng không
    ...
}
```

### ① Số lượng hợp lệ

```java
if (item.getQuantity() == null || item.getQuantity() <= 0) {
    throw new LoiNghiepVu("Số lượng của \"" + ... + "\" không hợp lệ...");
}
```

Chặn **cận dưới**. Mọi chốt khác trong hàm đều so sánh theo chiều "lớn hơn" (`> maxQty`,
`> ngưỡng tiền`), nên số âm lọt qua hết. Mà số lượng âm thì thành tiền âm, và **tổng đơn bị trừ
đi** — khách thêm 1 chuột 1.450.000đ kèm 1 bàn phím số lượng −1 sẽ ra tổng **−650.000đ**.

> Đây là câu trả lời rất tốt cho *"em kiểm tra dữ liệu đầu vào thế nào?"*: không chỉ chặn giá trị
> quá lớn, mà phải chặn cả **giá trị âm và giá trị null**.

### ② Hàng còn bán không

```java
private void validateConDangBan(List<CartItem> cartItems) {
    for (CartItem cartItem : cartItems) {
        if (!Boolean.TRUE.equals(p.getIsActive())) {
            throw new LoiNghiepVu("Sản phẩm \"" + p.getName()
                    + "\" đã ngừng kinh doanh. Vui lòng xóa khỏi giỏ hàng.");
        }
        ...kiểm biến thể tương tự...
    }
}
```

**Giỏ hàng là dữ liệu sống lâu.** Khách bỏ hàng vào giỏ rồi để đó vài ngày; trong lúc đó admin có
thể ngừng bán sản phẩm. Không kiểm ở đây thì khách vẫn đặt được món shop đã thôi kinh doanh, và
shop buộc phải hoặc đi tìm hàng cho bằng được, hoặc gọi điện xin lỗi hủy đơn.

**Vì sao chốt này đặt trước chốt thanh toán:** thứ tự có ý nghĩa nghiệp vụ. Nếu để sau, một đơn
giá trị lớn chứa hàng đã ngừng bán sẽ báo *"vui lòng thanh toán qua VNPAY"*; khách chuyển sang
VNPAY xong mới biết lý do thật. **Báo sai lý do còn tệ hơn không báo.** Nguyên tắc: kiểm "giỏ này
có hợp lệ không" trước, rồi mới xét "được trả bằng cách nào".

**Dùng `Boolean.TRUE.equals(x)` chứ không dùng `x == true`:** `isActive` là `Boolean` (có thể null).
Viết `if (!p.getIsActive())` mà giá trị là null thì Java tự mở hộp và ném `NullPointerException`.
`Boolean.TRUE.equals(null)` trả `false` — an toàn.

### ③ và ④ Chống bom hàng

```java
private void validateCodActiveOrderLimit(Order order) {
    if (!"COD".equals(order.getPaymentMethod())) return;    // VNPAY đã thu tiền -> không giới hạn
    long dangCho = orderRepository.countActiveCodOrders(order.getUser().getId());
    if (dangCho >= maxActive) {
        throw new LoiNghiepVu("Bạn đang có " + dangCho + " đơn COD chưa giao xong (tối đa "
                + maxActive + "). Vui lòng đợi giao xong, hoặc chọn thanh toán chuyển khoản
                (VNPAY) để đặt thêm ngay.");
    }
}
```

"Bom hàng" = đặt COD rồi không nhận, shop mất tiền ship hai chiều. Hai luật:

- **Giới hạn số đơn COD đang chờ giao** của mỗi khách (mặc định 3).
- **Đơn số lượng lớn hoặc giá trị lớn thì bắt buộc chuyển khoản trước** (mặc định > 3 sản phẩm
  hoặc > 4.000.000đ). Ngưỡng đọc từ bảng `system_settings` nên admin đổi được, không phải sửa code.

**Chỉ siết COD, không siết VNPAY** — vì VNPAY đã thu tiền trước, rủi ro bằng 0. Siết cả hai là
phạt nhầm khách thật.

Câu báo lỗi luôn **kèm lối thoát** ("hoặc chọn VNPAY để đặt thêm ngay"). Chặn khách mà không chỉ
đường ra là mất đơn hàng.

> **Ghi chú thiết kế đáng kể:** luật cũ là "cấm mua lại sản phẩm đã có đơn chưa giao". Đã bỏ vì
> phạt nhầm khách thật — mua 1 con chuột rồi muốn mua thêm bàn phím cũng bị chặn. Còn luật "chặn
> theo lịch sử hủy đơn của tài khoản" cũng bỏ, vì **khách chỉ cần tạo tài khoản mới là né được**,
> không có tác dụng thật.

### ⑤ Kiểm tồn kho — công thức quan trọng nhất

```java
if (variant != null) {
    onHand   = variant.getStock() != null ? variant.getStock() : 0;
    reserved = orderItemRepository.getReservedQtyByVariant(variant.getId());
} else {
    onHand   = p.getStockQuantity() ...;
    reserved = orderItemRepository.getTotalPendingQuantity(p.getId());
}
int availableQty = onHand - reserved;
if (availableQty < cartItem.getQuantity()) {
    throw new LoiNghiepVu("\"" + label + "\" không đủ hàng! "
            + "Còn có thể đặt: " + Math.max(0, availableQty) + " sản phẩm.");
}
```

**`số đặt được = tồn kho − số đã nằm trong đơn chưa giao`**

Phải trừ phần **đã giữ chỗ**. Kho còn 5 con nhưng cả 5 đã nằm trong đơn của người khác chưa giao
thì thực tế còn **0**. Không trừ là bán chồng, tới lúc xuất kho mới phát hiện thiếu hàng.

Kiểm **theo biến thể** nếu khách chọn màu (Model 2 — biến thể là đơn vị tồn kho). Sản phẩm không
có biến thể thì mới kiểm ở mức sản phẩm.

Câu lỗi nói rõ **còn đặt được mấy cái**, không bắt khách tự đoán bằng cách thử lùi dần.

`Math.max(0, availableQty)` — nếu đã bán chồng thì `availableQty` âm; hiện "Còn có thể đặt: −2"
là vô nghĩa với khách.

---

## B1.5 IDOR — lỗ hổng quyền sở hữu

**IDOR (Insecure Direct Object Reference)**: người dùng đổi số id trên URL để chạm vào dữ liệu
của người khác. Ví dụ đang xem `/my-orders/1041` (đơn của mình), sửa thành `/my-orders/1029`
để xem đơn người khác.

Cách chống trong dự án: **mọi chỗ nhận id từ URL đều phải kiểm chủ sở hữu**.

```java
// MyOrdersController.cancelOrder
Order order = orderService.findById(orderId).orElse(null);
if (order == null || !order.getUser().getId().equals(user.getId())) {
    ra.addFlashAttribute("loi", "Không tìm thấy đơn hàng này.");
    return "redirect:/my-orders";
}
```

**Chú ý câu thông báo:** đơn không tồn tại và đơn của người khác đều trả **cùng một câu**. Nếu
phân biệt ("đơn này không phải của bạn" vs "không tìm thấy đơn") thì kẻ xấu dò được **đơn nào có
tồn tại**, biết được shop đã bán bao nhiêu đơn. Đây gọi là **rò rỉ thông tin qua thông báo lỗi**.

Tương tự ở `CartService.removeItem(userId, cartItemId)` — luôn truyền kèm `userId`, không bao giờ
xóa chỉ theo `cartItemId`.

---

## B1.6 Hủy đơn — và vì sao phải luôn báo kết quả

```java
if (!OrderStatus.PENDING.equals(order.getStatus())) {
    ra.addFlashAttribute("loi", "Đơn #" + orderId + " đang ở trạng thái \""
            + nhanTrangThai(order.getStatus()) + "\" nên không tự hủy được nữa. "
            + "Vui lòng liên hệ shop để được hỗ trợ.");
    return "redirect:/my-orders";
}
boolean daTra = Boolean.TRUE.equals(order.getIsPaid());
orderService.updateStatus(orderId, OrderStatus.CANCELLED);
ra.addFlashAttribute("thanhCong", daTra
        ? "Đã hủy đơn #" + orderId + ". Đơn này đã thanh toán online, shop sẽ liên hệ hoàn tiền."
        : "Đã hủy đơn #" + orderId + ".");
```

**Khách chỉ tự hủy được khi đơn còn ở trạng thái "Chờ xác nhận".** Qua bước duyệt xuất kho rồi
thì hàng đã rời kho, hủy phải qua shop xử lý.

**Mọi nhánh đều phải báo kết quả.** Đây là nguyên tắc chống **lỗi im lặng**: nếu nhánh "không hủy
được" chỉ lặng lẽ redirect về, khách sẽ thấy trang tải lại mà đơn vẫn nằm đó, không hiểu vì sao —
rồi bấm lại vài lần và gọi điện cho shop. Hàm nào có nhánh "không làm gì cả" thì nhánh đó **bắt
buộc phải nói lý do**.

**Đơn đã trả tiền online thì báo thêm câu hoàn tiền**, để khách biết đường chờ chứ không tưởng
mất tiền.

---

## B1.7 Đánh giá sản phẩm

Luật: **chỉ khách đã mua và đơn đã hoàn thành mới được đánh giá**, mỗi người một sản phẩm một lần.
Kiểm ở `ReviewService`, không kiểm ở Controller — vì đây là luật kinh doanh.

> **Hỏi: Sao phải kiểm đã mua mới cho đánh giá?**
> **Đáp:** Chống đánh giá ảo. Không kiểm thì đối thủ tạo tài khoản vào cho 1 sao hàng loạt, hoặc
> chính shop tự tạo tài khoản cho 5 sao. Điểm đánh giá mất hết ý nghĩa.

---

## B1.8 Ngân hàng câu hỏi — Người 1

**1. Khách thêm hàng vào giỏ rồi để một tuần, trong lúc đó shop ngừng bán món đó. Chuyện gì xảy ra?**
> Lúc bấm đặt hàng sẽ bị chặn với thông báo "Sản phẩm ... đã ngừng kinh doanh, vui lòng xóa khỏi
> giỏ hàng". Ngay trong trang giỏ cũng đã có dòng cảnh báo đỏ dưới sản phẩm đó.
> *(Mở `OrderService.validateConDangBan` và `customer/cart.jsp` chỗ `.ct-off`.)*
> Lý do phải kiểm lại lúc đặt: giỏ hàng là dữ liệu sống lâu, trạng thái sản phẩm có thể đổi bất
> cứ lúc nào sau khi khách bỏ vào giỏ.

**2. Nếu em gõ tay `/cart/add?quantity=-5` thì sao?**
> Bị chặn hai lớp: `CartService.addToCart` kiểm số lượng > 0 ngay lúc thêm, và `OrderService`
> kiểm lại lần nữa lúc tạo đơn. Không chặn thì thành tiền âm và tổng đơn bị trừ đi, khách được
> cộng tiền. *(Mở test `soLuongAmTrongGio_thiBiChan`.)*

**3. Vì sao kiểm ở cả hai nơi? Không thừa à?**
> Không. Nguyên tắc **phòng thủ nhiều lớp**. `CartService` chặn đường thêm vào giỏ, nhưng dữ liệu
> có thể vào giỏ bằng đường khác (sửa trực tiếp DB, hoặc mai mốt thêm API cho app điện thoại).
> Chốt cuối trước khi ghi vào bảng `orders` phải tự đứng vững được. Ngoài ra DB còn có trigger
> `TRG_OrderItems_MaxQtyLimit` là lớp thứ ba.

**4. Hai khách cùng bấm mua con hàng cuối cùng cùng lúc?**
> Công thức `số đặt được = tồn kho − số đã giữ chỗ`. Người đặt trước làm `reserved` tăng lên,
> người sau tính ra `availableQty = 0` và bị chặn. `@Transactional` bảo đảm không để lại dữ liệu
> nửa vời. Và lúc thủ kho duyệt xuất kho còn kiểm tồn lần nữa.
> *(Mở test `hangDaBiDonKhacGiuCho_thiKhongTinhLaConHang`.)*

**5. Em phân trang thế nào? Nếu người dùng gõ `?page=99999`?**
> `Math.min(page, tongTrang)` kẹp về trang cuối. Và `Math.max(1, tongTrang)` để danh sách rỗng
> vẫn là 1 trang, tránh chia cho 0. Không kẹp thì `subList` ném `IndexOutOfBoundsException` ra
> trang 500.

**6. Sao lọc sản phẩm bằng Java mà không bằng SQL?**
> Trả lời theo B1.3 — và **chủ động nêu giới hạn**: cách này chỉ hợp với quy mô vài chục sản
> phẩm; lên hàng chục nghìn thì phải đẩy xuống DB và phân trang bằng SQL.

**7. Em đổi id đơn hàng trên URL thì xem được đơn người khác không?**
> Không. Mọi chỗ nhận id từ URL đều kiểm chủ sở hữu. Và thông báo cố ý viết chung một câu "Không
> tìm thấy đơn hàng này" cho cả hai trường hợp, để không lộ đơn nào có tồn tại.
> *(Mở `MyOrdersController.cancelOrder`.)*

**8. Khách hủy đơn lúc nào cũng được à?**
> Chỉ khi đơn còn "Chờ xác nhận". Qua bước duyệt xuất kho là hàng đã rời kho. Trường hợp không
> hủy được, hệ thống báo rõ đơn đang ở trạng thái nào và bảo liên hệ shop — chứ không im lặng
> không làm gì.

**9. Vì sao sau khi POST lại redirect thay vì trả trang luôn?**
> Mẫu POST–Redirect–GET. Trả thẳng trang thì khách bấm F5 sẽ gửi lại POST và tạo đơn trùng.
> Ngoài ra dự án còn có `static/js/form-guard.js` khóa nút sau lần bấm đầu, chống bấm hai lần liên tiếp.

**10. Trang so sánh sản phẩm hoạt động thế nào?**
> So toàn bộ `product_specs` của các sản phẩm được chọn. Vì mỗi phiên bản là một sản phẩm riêng
> có bộ thông số riêng, nên so sánh giữa các phiên bản cùng dòng cũng chạy đúng đường đó.

---

# PHẦN B2 — NGƯỜI 2: KHO VÀ TIỀN

> **Phạm vi:** nhập kho, xuất kho, trạng thái đơn hàng, bảo hành, báo cáo doanh thu và lãi lỗ.
> Đây là mảng **khô nhất nhưng hội đồng hỏi sâu nhất**, vì đây là chỗ ra tiền. Người phụ trách
> mảng này cần thuộc kỹ hai thứ: **trigger giữ tồn kho** và **FIFO giá vốn**.

## B2.1 Bản đồ code của Người 2

| File | Việc |
|---|---|
| `controller/WarehouseController` | Màn hình thủ kho: nhập kho, xem tồn, xem lịch sử lô |
| `controller/AdminOrderController` | Duyệt đơn, đổi trạng thái |
| `service/StockService` | Nhập kho, **xuất kho FIFO**, hoàn kho khi hủy đơn |
| `service/OrderService.approveExport` | Duyệt xuất kho |
| `service/OrderService.updateStatus` | **Máy trạng thái đơn hàng** |
| `service/WarrantyService` | Sinh phiếu bảo hành khi đơn hoàn thành |
| `service/DonQuaHanService` | Tác vụ nền: tự hủy đơn chuyển khoản quá hạn |
| `dao/StockReportDao` | Báo cáo nhập–xuất–tồn theo tháng |
| `dao/RevenueReportDao`, `dao/DashboardDao` | Báo cáo doanh thu, biểu đồ trang tổng quan |

Bảng DB: `stock_in`, `stock_out`, `orders`, `order_items`, `warranties`, `warranty_repairs`
+ **3 trigger**.

---

## B2.2 Trigger giữ tồn kho — câu hỏi ăn điểm hoặc mất điểm nặng nhất

### Vấn đề

Số tồn kho có thể tính từ nhiều nguồn:

- cột `products.stock_quantity`
- tổng `remaining_quantity` của các lô trong `stock_in`
- lấy tổng nhập trừ tổng xuất

Nếu **Java tự cộng trừ** vào cột `stock_quantity`, mà có **nhiều đường** cùng động vào tồn kho
(nhập kho, xuất kho, hủy đơn hoàn kho, admin sửa tay), thì chỉ cần **một đường quên cập nhật**
hoặc **một đường trừ hai lần** là con số lệch. Và lệch rồi thì **không ai biết**, vì không có gì
đối chiếu.

### Cách dự án giải quyết

**Chọn đúng một nguồn sự thật: bảng `stock_in`.** Cột `stock_quantity` và `product_variants.stock`
chỉ là **con số được tính lại**, do trigger trong SQL Server đảm nhiệm. Java **không bao giờ ghi**
vào hai cột này — trong entity chúng khai `updatable = false`.

**Ba trigger** (mở `share.sql` phần cuối để chỉ cho hội đồng):

```sql
-- Trigger 1: khi có dòng xuất kho, trừ đúng lô nhập tương ứng
CREATE TRIGGER TRG_StockOut_ApplyToStockIn ON stock_out AFTER INSERT
AS BEGIN
    UPDATE si SET si.remaining_quantity = si.remaining_quantity - i.quantity
    FROM stock_in si JOIN inserted i ON i.stock_in_id = si.id;
END
```

```sql
-- Trigger 2: mỗi khi stock_in đổi, TÍNH LẠI tồn của sản phẩm và biến thể
CREATE TRIGGER TRG_StockIn_SyncProductStock ON stock_in
AFTER INSERT, UPDATE, DELETE
AS BEGIN
    UPDATE p SET p.stock_quantity = ISNULL(
        (SELECT SUM(si.remaining_quantity) FROM stock_in si WHERE si.product_id = p.id), 0)
    FROM products p WHERE p.id IN (SELECT product_id FROM inserted
                                   UNION SELECT product_id FROM deleted);

    UPDATE v SET v.stock = ISNULL(
        (SELECT SUM(si.remaining_quantity) FROM stock_in si WHERE si.variant_id = v.id), 0)
    FROM product_variants v WHERE v.id IN (...);
END
```

```sql
-- Trigger 3: hàng rào cuối chặn số lượng vượt giới hạn mỗi đơn
CREATE TRIGGER TRG_OrderItems_MaxQtyLimit ON order_items AFTER INSERT, UPDATE
AS BEGIN
    DECLARE @maxQty INT;
    SELECT @maxQty = TRY_CAST(setting_value AS INT) FROM system_settings
     WHERE setting_key = N'MAX_QTY_PER_PRODUCT_PER_ORDER';
    IF @maxQty IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE quantity > @maxQty)
    BEGIN
        RAISERROR(N'Số lượng mua vượt quá giới hạn cho phép mỗi đơn hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
```

### Dây chuyền chạy như thế nào

```
Thủ kho bấm "Duyệt xuất kho"
        │
        ▼
StockService.stockOutFIFO()  ──ghi──▶  bảng stock_out
                                            │
                          TRG_StockOut_ApplyToStockIn tự chạy
                                            │
                                            ▼
                                  stock_in.remaining_quantity giảm
                                            │
                          TRG_StockIn_SyncProductStock tự chạy
                                            │
                                            ▼
              products.stock_quantity  và  product_variants.stock  được TÍNH LẠI
```

Java chỉ ghi **một dòng** vào `stock_out`. Mọi con số tồn kho sau đó là hệ quả tự động.

> **Hỏi (câu này gần như chắc chắn có): Sao không để Java tự cộng trừ tồn kho cho dễ?**
>
> **Đáp:** Vì tồn kho bị đụng tới từ **nhiều đường**: nhập kho, xuất kho, hủy đơn hoàn kho, gán lô
> vào biến thể. Nếu mỗi đường tự cộng trừ thì chỉ cần một đường quên hoặc trừ hai lần là số tồn
> sai, mà **sai âm thầm** — không có gì báo. Nhóm chọn cách chỉ có **một nguồn sự thật** là bảng
> `stock_in`, còn cột tồn là con số dẫn xuất do trigger tính lại. Trigger nằm trong DB nên **bất
> kỳ đường nào** động vào `stock_in` cũng kích hoạt, kể cả người quản trị sửa tay bằng SSMS.
> Trong code Java, hai cột đó khai `updatable = false` để chặn ghi nhầm ngay từ tầng ứng dụng.
>
> **Nếu bị vặn tiếp "trigger khó bảo trì, khó debug thì sao?"** — thừa nhận thẳng: đúng, trigger
> là logic ẩn, người mới đọc code Java sẽ không thấy nó. Nhóm bù lại bằng cách ghi chú rõ ngay
> tại `StockService` và ở đầu file `share.sql`. Đánh đổi này chấp nhận được vì **sai số tồn kho
> là loại lỗi không thể phát hiện bằng mắt**, còn trigger khó đọc thì chỉ tốn công đọc thêm.

---

## B2.3 Xuất kho FIFO — vì sao phải truy theo từng lô

### Vấn đề: giá vốn

Shop nhập 3 đợt cùng một con chuột:

| Lô | Ngày nhập | Số lượng | Giá nhập |
|---|---|---|---|
| #1 | 01/06 | 10 | 700.000đ |
| #2 | 15/06 | 10 | 750.000đ |
| #3 | 01/07 | 10 | 820.000đ |

Bán 1 con giá 966.000đ. **Lãi bao nhiêu?** Tùy con đó lấy từ lô nào: lãi 266.000đ, 216.000đ,
hay 146.000đ. Không truy được lô thì **không tính được lãi thật**.

### Cách giải: FIFO — hàng nhập trước xuất trước

Mở `service/StockService.java`, hàm `stockOutFIFO`.

```java
// Chọn đúng nguồn lô: có biến thể thì chỉ lấy lô của biến thể đó
List<StockIn> lots = (variant != null)
        ? stockInRepository.findVariantLotsFIFO(variant.getId())
        : stockInRepository.findProductLotsFIFO(productId);

// KIỂM ĐỦ HÀNG TRƯỚC KHI GHI BẤT KỲ DÒNG NÀO
int totalAvailable = lots.stream().mapToInt(StockIn::getRemainingQuantity).sum();
if (totalAvailable < quantityNeeded) {
    throw new LoiNghiepVu("Khong du ton kho de xuat: ... can " + quantityNeeded
            + " nhung cac lo chi con " + totalAvailable);
}

int remaining = quantityNeeded;
for (StockIn lot : lots) {                       // đã sắp theo ngày nhập tăng dần
    if (remaining <= 0) break;
    int takeFromLot = Math.min(remaining, lot.getRemainingQuantity());

    StockOut out = new StockOut();
    out.setOrderItem(orderItem);
    out.setStockIn(lot);                          // ← trỏ về ĐÚNG LÔ đã lấy hàng
    out.setQuantity(takeFromLot);
    out.setImportCost(lot.getImportPrice());      // ← CHỐT giá vốn thật tại thời điểm xuất
    stockOutRepository.save(out);

    lot.setRemainingQuantity(lot.getRemainingQuantity() - takeFromLot);
    remaining -= takeFromLot;
}
```

**Bốn chi tiết cố ý, đều đáng nói khi bảo vệ:**

1. **Kiểm đủ hàng TRƯỚC khi ghi dòng nào.** Nếu vừa ghi vừa kiểm, cần 10 mà chỉ có 7 thì đã ghi
   xong 7 dòng xuất kho rồi mới phát hiện thiếu — để lại dữ liệu xuất kho "nửa vời". Kiểm trước
   thì ném lỗi ngay, `@Transactional` rollback sạch.

2. **`out.setStockIn(lot)`** — mỗi dòng xuất trỏ về đúng lô nhập. Nhờ vậy sau này truy được:
   con chuột trong đơn #1038 lấy từ lô nào, nhập ngày nào, của nhà cung cấp nào.

3. **`out.setImportCost(lot.getImportPrice())`** — **chốt giá vốn ngay tại thời điểm xuất**.
   Không lưu mà sau này đi tra lại giá nhập thì giá đã đổi, báo cáo lãi lỗ của tháng cũ sẽ tự
   thay đổi theo. Nguyên tắc kế toán: **số liệu quá khứ không được đổi**.

4. **`lot.setRemainingQuantity(...)` chỉ cập nhật trong bộ nhớ**, không sinh câu UPDATE (cột khai
   `updatable = false`). Mục đích là để **vòng lặp và các lần gọi sau trong cùng transaction đọc
   đúng con số** — ví dụ một đơn có 2 màu của cùng một sản phẩm. Việc trừ thật trong DB do trigger
   làm. Nếu Java cũng trừ thì thành **trừ hai lần**.

Một đơn mua 15 con sẽ sinh ra nhiều dòng `stock_out`: 10 từ lô #1 giá 700.000đ, 5 từ lô #2 giá
750.000đ. Báo cáo lãi lỗ cộng chính xác từng phần.

---

## B2.4 Máy trạng thái đơn hàng

Mở `service/OrderService.java`:

```java
private static final Map<String, Set<String>> LUONG_HOP_LE = Map.of(
    OrderStatus.PENDING,        Set.of(SHIPPING, AWAITING_STOCK, CANCELLED),
    OrderStatus.AWAITING_STOCK, Set.of(SHIPPING, CANCELLED),
    OrderStatus.SHIPPING,       Set.of(COMPLETED, CANCELLED),
    OrderStatus.COMPLETED,      Set.of(),      // trạng thái cuối
    OrderStatus.CANCELLED,      Set.of());     // trạng thái cuối
```

```
  Chờ xác nhận ──┬──▶ Đang giao ──▶ Hoàn thành
   (PENDING)     │     (SHIPPING)    (COMPLETED)
                 ├──▶ Chờ hàng ──▶ Đang giao
                 │  (AWAITING_STOCK)
                 └──▶ Đã hủy (CANCELLED)
```

**Vì sao phải khai bảng này thay vì cho admin đổi tùy ý:**

Nhảy thẳng *Chờ xác nhận → Hoàn thành* là **lỗi nặng nhất có thể xảy ra với một shop**:

- đơn được đánh dấu xong xuôi,
- đơn COD ghi nhận **đã thu tiền**,
- phiếu bảo hành được sinh ra,
- **nhưng hàng chưa bao giờ rời kho** — không có dòng `stock_out` nào.

Hậu quả: tồn kho không giảm (bán rồi mà hệ thống tưởng còn hàng → bán tiếp), và báo cáo lãi lỗ
lấy **giá vốn = 0** nên lãi bị thổi phồng.

`COMPLETED` và `CANCELLED` là **trạng thái cuối** (`Set.of()` rỗng) — không cho quay ngược.
Đơn đã hủy mà mở lại được thì tồn kho đã hoàn về sẽ bị trừ lần hai.

Test bảo vệ luật này: `nhayThangTuChoXacNhanSangHoanThanh_thiBiChan`.

---

## B2.5 Chống duyệt xuất kho hai lần

```java
// OrderService.approveExport
if (!OrderStatus.PENDING.equals(order.getStatus())
        && !OrderStatus.AWAITING_STOCK.equals(order.getStatus())) {
    throw new LoiNghiepVu("Đơn này đã được duyệt xuất kho rồi (đang ở trạng thái \""
            + nhanTrangThai(order.getStatus()) + "\").");
}
```

Gọi hàm này hai lần cho cùng một đơn là **trừ tồn kho gấp đôi** mà không báo gì. Xảy ra rất dễ:
thủ kho bấm nút hai lần vì trang tải chậm, hoặc bấm F5 sau khi duyệt.

**Chốt đặt ở tầng Service, không đặt ở Controller.** Vì Controller có thể có nhiều đường gọi tới,
còn Service là chỗ duy nhất mọi đường đều phải đi qua. Ngoài ra `static/js/form-guard.js` khóa nút
sau lần bấm đầu — nhưng đó chỉ là lớp tiện lợi cho người dùng, không phải lớp bảo vệ thật.

Test: `duyetXuatKhoLanHai_thiBiChan`.

---

## B2.6 Báo cáo doanh thu — hai điểm phải nhớ

### Doanh thu phải trừ phí vận chuyển

Cột `orders.total_amount` **đã bao gồm phí ship**. Phí ship là tiền trả cho đơn vị vận chuyển,
**không phải doanh thu của shop**. Nên mọi truy vấn doanh thu đều viết:

```sql
SUM(total_amount - ISNULL(shipping_fee, 0))
```

Có **7 truy vấn** trong `DashboardDao` và `RevenueReportDao` đều phải trừ như vậy. Sót một chỗ
là các con số trên trang tổng quan và trang báo cáo **lệch nhau**, hội đồng nhìn ra ngay.

`ISNULL(shipping_fee, 0)` vì đơn cũ tạo trước khi có tính năng phí ship sẽ có cột này NULL, mà
`số − NULL = NULL` trong SQL → doanh thu của cả tháng đó thành NULL.

### Báo cáo là chứng từ của một tháng đã qua

Mở `dao/StockReportDao.java`, hàm `getStockReport`:

```sql
WHERE p.is_active = 1
   OR p.stock_quantity > 0
   OR EXISTS (SELECT 1 FROM stock_in si3 WHERE si3.product_id = p.id
                AND YEAR(si3.imported_at) = ? AND MONTH(si3.imported_at) = ?)
   OR EXISTS (SELECT 1 FROM stock_out se3 JOIN order_items oi3 ON oi3.id = se3.order_item_id
                WHERE oi3.product_id = p.id AND se3.is_returned = 0
                  AND YEAR(se3.exported_at) = ? AND MONTH(se3.exported_at) = ?)
```

Điều kiện này để làm gì: báo cáo lấy **cả sản phẩm đã ngừng bán**, miễn là tháng đó có phát sinh
nhập/xuất hoặc còn tồn.

**Vì sao không lọc gọn `WHERE p.is_active = 1`:** báo cáo kho là **chứng từ của một tháng đã qua**.
Lọc theo trạng thái *hiện tại* thì tháng 3 nhập 100 con chuột X, tháng 6 ngừng bán X, mở lại báo
cáo tháng 3 sẽ **không còn dòng nào** của X — số liệu quá khứ tự thay đổi theo hiện tại. Kế toán
không chấp nhận điều đó.

---

## B2.7 Tác vụ nền — tự hủy đơn quá hạn

`service/DonQuaHanService.java`:

```java
@Scheduled(fixedDelay = 5 * 60 * 1000, initialDelay = 60 * 1000)
public void huyDonQuaHan() { ... }
```

Đơn chọn VNPAY nhưng khách không thanh toán sẽ nằm mãi ở `PENDING` và **giữ chỗ tồn kho** — hàng
còn trong kho nhưng không ai mua được. Cứ 5 phút quét một lần, đơn VNPAY chưa trả quá 15 phút thì
tự hủy và nhả tồn kho ra.

**Chi tiết dễ sai:** `@Scheduled` **chỉ chạy khi có `@EnableScheduling`** trong `AppConfig`.
Thiếu annotation đó thì Spring **bỏ qua lặng lẽ** — không lỗi, không log, chỉ đơn giản là không
bao giờ chạy. Đây là loại lỗi im lặng khó phát hiện nhất, nên trong `AppConfig` có ghi chú cảnh
báo ngay tại dòng đó.

---

## B2.8 Ngân hàng câu hỏi — Người 2

**1. Tồn kho của em lưu ở đâu? Ai cập nhật nó?**
> Nguồn sự thật duy nhất là bảng `stock_in`, cụ thể là tổng `remaining_quantity` của các lô.
> Hai cột `products.stock_quantity` và `product_variants.stock` chỉ là con số dẫn xuất, do **3
> trigger trong SQL Server** tính lại. Java không ghi vào hai cột đó — entity khai `updatable = false`.
> *(Mở `share.sql` phần trigger.)*

**2. Sao không để Java tính cho dễ debug?**
> Trả lời theo B2.2. Nhấn: tồn kho bị đụng từ nhiều đường, một đường quên là sai âm thầm; trigger
> nằm trong DB nên mọi đường đều kích hoạt, kể cả sửa tay bằng SSMS. Và **chủ động nêu đánh đổi**:
> trigger là logic ẩn khó đọc, nhóm bù bằng ghi chú trong code và trong file SQL.

**3. FIFO là gì? Sao phải làm FIFO?**
> Hàng nhập trước xuất trước. Cần vì mỗi lô nhập có **giá vốn khác nhau**, không truy theo lô thì
> không tính được lãi thật. Mỗi dòng `stock_out` trỏ về đúng lô, và chốt luôn `import_cost` tại
> thời điểm xuất để báo cáo tháng cũ không bị đổi khi giá nhập thay đổi.
> *(Mở `StockService.stockOutFIFO`.)*

**4. Đơn mua 15 con mà lô đầu chỉ còn 10 thì sao?**
> Vòng lặp lấy 10 từ lô cũ nhất, 5 từ lô kế tiếp, sinh **hai dòng** `stock_out` với hai giá vốn
> khác nhau. Báo cáo lãi lỗ cộng chính xác từng phần.

**5. Nếu kho không đủ hàng lúc xuất?**
> Kiểm tổng tồn của tất cả các lô **trước khi ghi dòng nào**, thiếu là ném `LoiNghiepVu` ngay,
> `@Transactional` rollback sạch. Nếu vừa ghi vừa kiểm thì sẽ để lại dữ liệu xuất kho nửa vời.

**6. Admin có đổi trạng thái đơn tùy ý được không?**
> Không. Có bảng `LUONG_HOP_LE` khai rõ từ trạng thái nào đi được tới đâu.
> *(Mở `OrderService.LUONG_HOP_LE`.)* Đặc biệt cấm nhảy thẳng *Chờ xác nhận → Hoàn thành*, vì như
> vậy đơn được đánh dấu xong, COD ghi đã thu tiền, phiếu bảo hành được sinh, **nhưng hàng chưa
> rời kho** — tồn kho không giảm và báo cáo lấy giá vốn bằng 0.

**7. Thủ kho bấm duyệt xuất kho hai lần thì sao?**
> Bị chặn ở `approveExport`, vì đơn đã chuyển sang `SHIPPING` không còn ở `PENDING`/`AWAITING_STOCK`.
> Không chặn là trừ tồn gấp đôi. *(Mở test `duyetXuatKhoLanHai_thiBiChan`.)*

**8. Doanh thu tính thế nào? Có tính phí ship không?**
> Không tính. `total_amount` đã gồm phí ship, mà phí ship trả cho bên vận chuyển. Mọi truy vấn
> doanh thu đều dùng `SUM(total_amount - ISNULL(shipping_fee,0))`, tổng cộng 7 chỗ, phải nhất
> quán hết nếu không trang tổng quan và trang báo cáo sẽ lệch nhau.

**9. Khách hủy đơn đã xuất kho rồi thì tồn kho có về không?**
> Có. Hủy đơn gọi hoàn kho, các dòng `stock_out` chưa hoàn được đánh dấu `is_returned` và tồn được
> trả lại đúng lô. Nhưng khách **không tự hủy** được ở trạng thái đó — phải qua shop.

**10. Đơn VNPAY khách không trả tiền thì nằm đó mãi à?**
> Không. `DonQuaHanService` chạy nền mỗi 5 phút, đơn VNPAY chưa thanh toán quá 15 phút thì tự hủy
> và nhả tồn kho. Không có nó thì hàng bị giữ chỗ vĩnh viễn, còn trong kho nhưng không ai mua được.

**11. Báo cáo kho tháng 3 mà giờ là tháng 8, sản phẩm đã ngừng bán, có còn thấy không?**
> Còn. Điều kiện lọc cố ý lấy cả sản phẩm ngừng bán nếu tháng đó có phát sinh nhập/xuất hoặc còn
> tồn. Báo cáo là chứng từ của tháng đã qua, không được thay đổi theo trạng thái hiện tại.

**12. Phiếu bảo hành sinh lúc nào?**
> Khi đơn chuyển sang `COMPLETED`. Do đó luật cấm nhảy thẳng từ `PENDING` sang `COMPLETED` còn có
> tác dụng chặn việc sinh phiếu bảo hành cho hàng chưa bao giờ giao.

---

# PHẦN B3 — NGƯỜI 3: KHUYẾN MÃI, QUẢN TRỊ, BẢO MẬT

> **Phạm vi:** combo, flash sale, mã giảm giá, quản lý tài khoản, nhật ký thao tác, và **toàn bộ
> phần bảo mật**. Mảng này có câu chuyện gây ấn tượng mạnh nhất với hội đồng (mục B3.4).

## B3.1 Bản đồ code của Người 3

| File | Việc |
|---|---|
| `service/ComboService` | Combo "Góc máy đồng bộ" — giá bộ, chia tiền giảm |
| `service/FlashSaleService` | Đợt giảm giá theo thời gian |
| `service/VoucherService` | Mã giảm giá, có loại chỉ dùng cho combo |
| `controller/AdminUserController` | Quản lý tài khoản |
| `controller/AdminSettingsController` | Cài đặt hệ thống |
| `service/AuditLogService` | Nhật ký thao tác |
| `config/SecurityConfig` | Đăng nhập, phân quyền, CSRF |
| `static/js/post-link.js` | Biến link hành động thành POST kèm token |
| `exception/LoiNghiepVu` | Lớp lỗi nghiệp vụ |

Bảng DB: `combos`, `combo_items`, `flash_sales`, `flash_sale_items`, `vouchers`,
`voucher_usages`, `users`, `audit_log`, `system_settings`.

---

## B3.2 Combo — bài toán chia tiền khó nhất dự án

### Combo là gì trong dự án này

Admin tạo một bộ, ví dụ "Góc máy Gaming" gồm 1 chuột + 1 bàn phím + 1 tai hone, và đặt **số tiền
giảm** cho cả bộ. Khách được **chọn phiên bản và màu** cho từng vị trí trong bộ, chứ không phải
nhận đúng cấu hình admin xếp sẵn.

### Bài toán: chia tiền giảm về từng dòng

Đơn hàng lưu theo **từng dòng sản phẩm** (`order_items`), mỗi dòng có đơn giá và thành tiền.
Nhưng tiền giảm lại đặt cho **cả bộ**. Vậy phải chia số tiền giảm đó về từng dòng.

Chia theo tỉ lệ rồi làm tròn từng dòng sẽ **lệch vài đồng** so với giá bộ mà khách đã nhìn thấy.
Khách thấy 2.500.000đ mà hóa đơn ghi 2.500.002đ là mất lòng tin ngay.

### Đoạn code này để làm gì

```java
BigDecimal daChia = BigDecimal.ZERO;
for (int i = 0; i < cacDong.size(); i++) {
    BigDecimal thanhTienMoi;
    if (i == cacDong.size() - 1) {
        // Dòng CUỐI nhận phần còn lại, để tổng khớp TUYỆT ĐỐI với giá bộ
        thanhTienMoi = mucTieu.subtract(daChia);
    } else {
        thanhTienMoi = thanhTienGoc.multiply(mucTieu).divide(tong, 0, RoundingMode.HALF_UP);
        daChia = daChia.add(thanhTienMoi);
    }
    ...
}
```

Chia theo tỉ lệ cho các dòng đầu, **dòng cuối lấy phần còn thiếu**. Nhờ vậy tổng luôn khớp
tuyệt đối với giá bộ, không lệch một đồng nào.

Và lúc ghi vào `order_items`:

```java
item.setLineTotal(gia.getThanhTien());   // lấy thẳng thành tiền đã chia
```

**Không nhân lại `đơn giá × số lượng`** — vì phần lẻ đã được dồn vào dòng cuối, nhân lại là lệch
so với con số khách đã thấy.

### Vì sao dùng `BigDecimal` chứ không dùng `double`

Câu này hội đồng rất hay hỏi.

```java
// double sai:
System.out.println(0.1 + 0.2);   // ra 0.30000000000000004
```

`double` lưu số theo hệ nhị phân, nhiều số thập phân không biểu diễn chính xác được. Với tiền thì
sai số cộng dồn qua hàng nghìn đơn hàng thành con số thật. `BigDecimal` lưu chính xác và **bắt
người viết code chỉ rõ cách làm tròn** (`RoundingMode.HALF_UP`), không để máy tự quyết.

### Chốt an toàn giá bộ

```java
private BigDecimal chotGiaBo(Combo combo, BigDecimal giaNiemYet, BigDecimal giaBanLe) {
    BigDecimal tienGiam = combo.getDiscountAmount() == null ? BigDecimal.ZERO : ...;
    if (tienGiam.compareTo(giaNiemYet) >= 0) {
        log.warn("Combo #{} có tiền giảm {} ≥ tổng giá bộ {} -> ẩn combo", ...);
        return null;      // trả null = không bán bộ này
    }
    return giaNiemYet.subtract(tienGiam).min(giaBanLe);
}
```

Hai việc:

1. **Tiền giảm ≥ tổng giá bộ thì ẩn combo đi** thay vì bán giá 0đ hoặc giá âm. Xảy ra khi admin
   đặt mức giảm rồi sau đó hạ giá sản phẩm xuống — con số vốn hợp lệ trở thành sai theo thời gian.
   Đây là lý do phải có **lớp chặn thứ hai lúc hiển thị**, chứ không chỉ chặn ở form admin.
2. **`.min(giaBanLe)`** — giá bộ không bao giờ được cao hơn tổng giá mua lẻ từng món. Mua theo bộ
   mà đắt hơn mua lẻ là phi lý.

### Kiểm phía server khi khách chọn phiên bản/màu

Khách chọn được phiên bản và màu, nghĩa là **dữ liệu do khách gửi lên**. Không kiểm thì khách sửa
HTML để ghép một con chuột 5 triệu vào vị trí lẽ ra chỉ cho chuột 1 triệu, rồi hưởng mức giảm của
cả bộ. `ComboService` kiểm lại: mỗi vị trí đúng một dòng, đúng số lượng, và sản phẩm phải **nằm
trong danh sách được phép** của vị trí đó.

> **Nguyên tắc chung, câu này ăn điểm:** *"Mọi lựa chọn khách gửi lên đều phải kiểm lại ở server
> bằng danh sách cho phép. Ẩn nút hay khóa dropdown ngoài giao diện chỉ là tiện lợi, không phải
> bảo mật."*

---

## B3.3 Flash sale — chặn bán giá 0đ

Mở `service/FlashSaleService.java`, hàm `saveItems`.

```java
if (type == FlashSaleItem.DiscountType.PERCENT) {
    if (value.compareTo(new BigDecimal("100")) >= 0) {
        throw new LoiNghiepVu("Phần trăm giảm của \"" + product.getName()
                + "\" phải nhỏ hơn 100% — giảm 100% là bán giá 0đ.");
    }
} else {
    BigDecimal gia = product.getPrice() != null ? product.getPrice() : BigDecimal.ZERO;
    if (value.compareTo(gia) >= 0) {
        throw new LoiNghiepVu("Mức giảm của \"" + product.getName() + "\" ("
                + value.toPlainString() + "đ) bằng hoặc lớn hơn giá bán ("
                + gia.toPlainString() + "đ) — sẽ thành bán giá 0đ.");
    }
}
```

**Để làm gì:** chặn hàng bị bán giá 0đ. Admin gõ nhầm `100` thay vì `10`, hoặc thừa một số 0 ở
mức giảm tiền mặt (5.000.000 thay vì 500.000), là sản phẩm thành 0đ. Và **không có lớp nào phía
sau chặn lại**: đơn vẫn tạo được, vẫn xuất kho được, doanh thu ghi 0.

```java
java.util.Set<Integer> daThem = new java.util.HashSet<>();
...
if (!daThem.add(productId)) {
    throw new LoiNghiepVu("Sản phẩm \"" + product.getName()
            + "\" bị thêm 2 lần trong cùng một đợt. Mỗi sản phẩm chỉ được 1 mức giảm.");
}
```

**Để làm gì:** chặn cùng một sản phẩm được thêm hai lần với hai mức giảm khác nhau trong cùng một
đợt. Nếu để lọt, sản phẩm đó có hai mức giảm cùng lúc — mà truy vấn của **trang danh sách** và
**trang chi tiết** sắp xếp khác nhau, nên hai trang sẽ hiện **hai giá khác nhau** cho cùng một món.

```java
// toggleActive — kiểm lại chồng lịch khi BẬT một đợt
if (batLen) {
    for (FlashSaleItem it : flashSaleItemRepository.findByFlashSaleId(id)) {
        List<FlashSaleItem> trung = flashSaleItemRepository.findOverlapping(
                it.getProduct().getId(), id, fs.getStartAt(), fs.getEndAt());
        if (!trung.isEmpty()) throw new LoiNghiepVu("Không bật được đợt này: ...");
    }
}
```

**Để làm gì:** chốt chống chồng lịch chỉ đếm các đợt **đang bật**. Nếu không kiểm lại lúc bật thì
có kẽ hở: tắt đợt A → tạo đợt B cùng khoảng thời gian (qua được vì A đang tắt) → bật lại A →
hai đợt chồng nhau.

---

## B3.4 Bảo mật — phần gây ấn tượng mạnh nhất

### Nguyên tắc: thao tác đổi dữ liệu phải là POST

Nhắc lại từ A5: **Spring Security chỉ kiểm token CSRF trên POST/PUT/PATCH/DELETE. GET được miễn
hoàn toàn.**

Nghĩa là nếu để một thao tác xóa dữ liệu chạy bằng GET, nó **không có lớp bảo vệ nào**. Kẻ xấu chỉ
cần dụ người quản trị đang đăng nhập mở một trang web bất kỳ có chèn:

```html
<img src="http://localhost:8080/admin/users/5/delete">
```

Trình duyệt tự động đính kèm cookie phiên → **tài khoản #5 bị xóa**. Không cần JavaScript, không
cần form, thẻ `<img>` là đủ. Với khách hàng thì `<img src=".../my-orders/123/cancel">` là đơn bị hủy.

Vì vậy **toàn bộ 9 thao tác đổi dữ liệu trong dự án đều là POST**: xóa sản phẩm, xóa tài khoản,
xóa/bật/tắt flash sale, bật/tắt voucher, bật/tắt combo, ẩn biến thể, hủy đơn, xóa món khỏi giỏ.

### Đoạn code này để làm gì — `static/js/post-link.js`

Vấn đề: giao diện muốn giữ nguyên hình dạng nút bấm (thẻ `<a>` với class CSS sẵn có), nhưng
request phải là POST kèm token.

```javascript
document.addEventListener('click', function (e) {
  var a = e.target.closest('a[data-post]');
  if (!a) return;
  e.preventDefault();

  var loiNhac = a.getAttribute('data-confirm');
  if (loiNhac && !window.confirm(loiNhac)) return;

  var form = document.createElement('form');
  form.method = 'POST';
  form.action = a.getAttribute('href');

  var input = document.createElement('input');
  input.type = 'hidden';
  input.name  = the('_csrf_param');    // đọc từ thẻ <meta>
  input.value = the('_csrf');
  form.appendChild(input);

  document.body.appendChild(form);
  form.submit();
});
```

Bắt cú click trên mọi thẻ `<a data-post>`, dựng một form ẩn kèm token, rồi gửi POST. Trong JSP chỉ
cần thêm hai thuộc tính, không đụng gì tới CSS:

```html
<a href="/admin/users/${u.id}/delete" data-post
   data-confirm="Xóa tài khoản này?" class="btn-delete">Xóa</a>
```

**Nếu trình duyệt tắt JavaScript** thì link chạy GET và nhận **405 Method Not Allowed** — đúng ý:
thà không làm gì còn hơn âm thầm xóa dữ liệu.

Token được nhúng ở `common/admin-topbar.jsp` (mọi trang quản trị) và `common/footer.jsp` (mọi
trang khách):

```jsp
<meta name="_csrf" content="${_csrf.token}">
<meta name="_csrf_param" content="${_csrf.parameterName}">
```

> **Cách demo trước hội đồng — rất ấn tượng:** mở tab mới, gõ thẳng
> `http://localhost:8080/admin/users/5/delete` vào thanh địa chỉ (đó chính là request GET). Màn
> hình trả **405**, không có gì bị xóa. Rồi giải thích: trước khi chuyển sang POST, chính đường
> dẫn này bị gọi bằng GET là tài khoản biến mất.

### Vì sao trang lỗi khai `@RequestMapping` chứ không phải `@GetMapping`

```java
// controller/ErrorController.java
@RequestMapping("/403")     // KHÔNG dùng @GetMapping
public String accessDenied() { return "common/403"; }
```

Spring Security khai `accessDeniedPage("/403")`, và nó **forward** tới đường dẫn đó chứ không
redirect. Forward **giữ nguyên method** của request gốc. Nên khi một request POST bị từ chối
(token hết hạn, hoặc không đủ quyền), cái forward đó cũng là POST — nếu chỉ nhận GET thì Spring
trả 405 và người dùng thấy trang "400 – Yêu cầu không hợp lệ" thay vì trang 403 tử tế.

**Ca gặp thật:** admin mở trang quản trị rồi để đó tới khi hết phiên đăng nhập, quay lại bấm nút
Xóa — token trong trang đã cũ, request bị chặn, và lẽ ra phải được báo "hết phiên, đăng nhập lại".

### Chặn XSS ở JSP

```jsp
${fn:escapeXml(product.name)}
```

Cú pháp `${...}` của JSP **không tự chuyển ký tự đặc biệt thành ký tự an toàn**. Nếu tên sản phẩm
chứa `<script>alert(1)</script>` thì đoạn đó chạy thật trong trình duyệt người xem. `fn:escapeXml`
chuyển `<` thành `&lt;` nên chỉ hiển thị ra chữ.

---

## B3.5 Quản lý tài khoản

### Đoạn code này để làm gì — chặn xóa cứng tài khoản

```java
public void deleteUser(Integer userId) {
    User u = userRepository.findById(userId).orElseThrow(...);

    int soDon = orderRepository.findByUserId(userId).size();
    if (soDon > 0) {
        throw new LoiNghiepVu("Tài khoản \"" + u.getEmail() + "\" đã có " + soDon
                + " đơn hàng nên không xóa được — xóa là mất luôn lịch sử mua bán. "
                + "Hãy dùng nút Khóa để chặn đăng nhập.");
    }
    if (reviewRepository.countByUserId(userId) > 0) { throw ... }
    if (!"CUSTOMER".equals(u.getRole()) && stockOutRepository.countByExportedById(userId) > 0) { throw ... }
    if ("ADMIN".equals(u.getRole()) && userRepository.findByRole("ADMIN").size() <= 1) { throw ... }

    userRepository.deleteById(userId);
}
```

Bảng `users` đang bị **5 bảng trỏ tới**: `orders`, `reviews`, `cart_items`, `stock_out.exported_by`,
`flash_sales.created_by`. Xóa một khách đã từng mua hàng sẽ rơi vào một trong hai kết cục, cả hai
đều tệ:

- khóa ngoại chặn → lỗi SQL thô văng ra trang 500, admin không hiểu gì;
- hoặc nếu khóa ngoại khai `ON DELETE CASCADE` → **toàn bộ đơn hàng của khách biến mất**, doanh
  thu các tháng cũ tụt xuống mà không hề báo.

**Lịch sử mua bán là chứng từ, không được mất theo tài khoản.** Muốn chặn một người dùng thì
**khóa** tài khoản, dữ liệu vẫn còn nguyên.

Chốt cuối cùng chặn xóa **admin duy nhất** — xóa xong thì không ai vào được trang quản trị nữa,
phải sửa tay trong SQL Server mới cứu được.

### Đoạn code này để làm gì — danh sách vai trò hợp lệ

```java
private static final java.util.Set<String> VAI_TRO_HOP_LE =
        java.util.Set.of("ADMIN", "WAREHOUSE", "CUSTOMER");
...
if (!VAI_TRO_HOP_LE.contains(role)) {
    model.addAttribute("error", "Vai trò không hợp lệ.");
    return "admin/user-form";
}
```

Trường `role` nhận từ form. Lưu thẳng chuỗi form gửi lên thì sửa HTML (hoặc gõ tay request) là tạo
được tài khoản role `admin` viết thường hay `ADMINN` — Spring Security so khớp `hasRole()` không
trúng cái nào, tài khoản tạo ra không vào được đâu mà cũng chẳng báo lỗi gì. Đây là kiểu **danh
sách cho phép (allow-list)**: chỉ nhận đúng những giá trị đã liệt kê, mọi thứ khác từ chối.

### Không tự khóa/tự xóa chính mình

```java
private boolean laChinhMinh(Integer id, Principal principal) { ... }
```

Bấm nhầm một cái là tự cắt quyền quản trị của mình, phải vào tận SQL Server sửa tay mới đăng nhập
lại được. Chặn ở tầng server chứ không chỉ ẩn nút ngoài giao diện.

---

## B3.6 Nhật ký thao tác

`service/AuditLogService.java` ghi lại các thao tác nhạy cảm: sửa giá, đổi trạng thái đơn, hủy đơn,
duyệt xuất kho, đổi cài đặt hệ thống, **nhập kho**.

```java
public void ghi(String hanhDong, String bang, Integer banGhiId, String truoc, String sau, String moTa) {
    try {
        ...lưu vào bảng audit_log...
    } catch (Exception e) {
        log.error("Không ghi được nhật ký ...", e);   // NUỐT lỗi
    }
}
```

**Vì sao bọc toàn bộ trong try/catch và nuốt lỗi:** ghi nhật ký là việc **phụ**. Nếu bảng
`audit_log` có sự cố mà làm hỏng luôn việc chính (nhập kho, duyệt đơn) thì thiệt hại lớn hơn nhiều
so với việc mất một dòng nhật ký. Nguyên tắc: **việc phụ không bao giờ được làm hỏng việc chính**.

**Vì sao nhập kho phải được ghi nhật ký:** đây là chỗ nhập **giá vốn** từng lô. Giá vốn quyết định
toàn bộ báo cáo lãi lỗ — gõ nhầm một con số là lãi sai cả tháng, và không ghi lại thì không truy
được ai nhập.

> **Hỏi: Admin phân quyền cho thủ kho sửa gì đó thì thao tác của thủ kho có vào nhật ký không?**
> **Đáp:** Có. Nhật ký ghi theo **thao tác**, không theo vai trò — mỗi dòng lưu ai làm, làm gì,
> giá trị trước và sau. Nhập kho là việc của thủ kho và được ghi đầy đủ.
> *(Mở trang Nhật ký thao tác chỉ dòng `NHAP_KHO`.)*

---

## B3.7 Ngân hàng câu hỏi — Người 3

**1. Web của em chống CSRF thế nào?**
> Spring Security bật CSRF toàn site, chỉ miễn trừ webhook thanh toán (server bên ngoài gọi tới,
> không thể có token của mình, endpoint đó tự bảo vệ bằng API key trong header). Mọi form đều nhúng
> token. Và vì Spring chỉ kiểm token trên POST/PUT/DELETE nên **mọi thao tác đổi dữ liệu đều phải
> là POST** — có 9 chỗ như vậy. *(Demo bằng cách gõ URL xóa vào thanh địa chỉ → 405.)*

**2. Nếu để xóa bằng link GET thì sao?**
> Kể kịch bản `<img src=".../admin/users/5/delete">` ở B3.4. Đây là câu trả lời gây ấn tượng mạnh
> nhất, nên tập kể cho trôi.

**3. Mã giảm giá của em có bị dùng lại nhiều lần không?**
> Không. Có bảng `voucher_usages` ghi ai đã dùng mã nào, và cờ `oncePerUser`. Kiểm ở
> `VoucherService`, trong transaction cùng với việc tạo đơn.

**4. Giá combo tính thế nào? Có bị lệch tiền không?**
> Trả lời theo B3.2: chia theo tỉ lệ, **dòng cuối nhận phần lẻ** nên tổng khớp tuyệt đối. Và
> `order_items.line_total` lấy thẳng số đã chia, không nhân lại đơn giá.

**5. Sao dùng `BigDecimal` mà không dùng `double`?**
> `0.1 + 0.2` trong `double` ra `0.30000000000000004`. Với tiền thì sai số cộng dồn thành tiền
> thật. `BigDecimal` chính xác và bắt phải chỉ rõ cách làm tròn.

**6. Khách sửa HTML để chọn sản phẩm đắt hơn vào combo thì sao?**
> Bị chặn. Server kiểm lại từng vị trí: đúng số lượng, và sản phẩm phải nằm trong danh sách được
> phép của vị trí đó. Ẩn/khóa ngoài giao diện chỉ là tiện lợi, không phải bảo mật.

**7. Admin gõ nhầm giảm 100% thì sao?**
> Bị chặn ngay ở form với thông báo "phải nhỏ hơn 100% — giảm 100% là bán giá 0đ". Tương tự với
> mức giảm tiền mặt lớn hơn giá bán. Vì phía sau không có lớp nào chặn nữa: đơn vẫn tạo, vẫn xuất
> kho, doanh thu ghi 0.

**8. Xóa tài khoản khách đã mua hàng thì đơn hàng cũ ra sao?**
> Không xóa được. Hệ thống báo tài khoản đã có bao nhiêu đơn và bảo dùng nút Khóa thay thế. Lịch sử
> mua bán là chứng từ, không được mất theo tài khoản.

**9. Nhật ký thao tác ghi những gì? Nếu ghi nhật ký lỗi thì sao?**
> Ghi sửa giá, đổi trạng thái đơn, hủy đơn, duyệt xuất kho, đổi cài đặt, nhập kho — kèm ai làm,
> giá trị trước và sau. Nếu ghi nhật ký lỗi thì **nuốt lỗi**, việc chính vẫn chạy: việc phụ không
> được làm hỏng việc chính.

**10. Phân quyền của em làm ở đâu? Ẩn nút có đủ không?**
> Ở `SecurityConfig` theo đường dẫn, cộng với kiểm quyền sở hữu ở từng chỗ động vào dữ liệu người
> khác. **Ẩn nút không phải là bảo mật** — ai cũng gõ được URL thẳng vào thanh địa chỉ.

---

# PHẦN C — CÂU HỎI HÓC BÚA (kiểu giám đốc kỹ thuật 20 năm)

> Đây là những câu **không hỏi về cú pháp mà hỏi về suy nghĩ**. Nguyên tắc trả lời: **nói thẳng
> giới hạn của mình**. Người có kinh nghiệm đánh giá cao sinh viên biết hệ thống mình yếu ở đâu,
> hơn nhiều so với sinh viên khăng khăng sản phẩm mình hoàn hảo.

**C1. Nếu mai shop có 10.000 đơn/ngày, chỗ nào vỡ trước?**
> Chỗ vỡ đầu tiên là **trang danh sách sản phẩm** — hiện đang nạp toàn bộ sản phẩm rồi lọc trong
> bộ nhớ Java. Thứ hai là `Product.specs/variants` để EAGER, mỗi lần nạp kéo theo nhiều dữ liệu
> thừa. Hướng xử lý: đẩy bộ lọc và phân trang xuống SQL, chuyển sang LAZY kèm `JOIN FETCH` đúng
> chỗ cần, và thêm bộ nhớ đệm cho danh mục.

**C2. Hai người cùng bấm mua con hàng cuối cùng đúng một phần nghìn giây. Chắc chắn không bán chồng chứ?**
> **Trả lời trung thực:** ở mức đề tài thì đủ an toàn, nhưng chưa phải tuyệt đối. Hiện có ba lớp:
> công thức trừ phần đã giữ chỗ, `@Transactional`, và kiểm lại lúc xuất kho. Trong tình huống chạy
> song song cực sát nhau, hai transaction đều có thể đọc thấy `availableQty = 1` trước khi bên nào
> kịp ghi. Muốn tuyệt đối thì phải dùng **khóa bi quan** (`SELECT ... FOR UPDATE`) hoặc **khóa lạc
> quan** bằng cột `@Version` trên `product_variants`. Nhóm chưa làm vì lưu lượng của đề tài không
> tới mức đó, nhưng biết rõ cần thêm gì.
>
> *(Câu này trả lời được là ăn điểm rất cao. Nói "chắc chắn không bao giờ sai" là mất điểm.)*

**C3. Em test được bao nhiêu phần trăm code?**
> 60 test, tập trung **tầng nghiệp vụ** — nơi chứa luật kinh doanh. Chưa đo độ phủ bằng công cụ và
> chưa có test cho tầng Controller hay test đầu-cuối. Nhóm chọn ưu tiên test những luật mà sai là
> mất tiền: máy trạng thái đơn, chống bán quá tồn, chống số lượng âm, chống duyệt xuất kho hai lần.

**C4. Nếu anh cho em làm lại từ đầu, em đổi gì?**
> Ba thứ. Một, thiết kế `product_variants` là đơn vị tồn kho **ngay từ đầu** thay vì thêm vào sau —
> vì đổi giữa chừng để lại những lô hàng nhập trước khi có biến thể, phải viết thêm chức năng gán
> lô. Hai, đặt cấu hình Spring vào **root context** thay vì dồn hết vào servlet context, để dùng
> được các filter cấp container. Ba, quy ước **thao tác đổi dữ liệu luôn là POST** ngay từ đầu.

**C5. Ai đó xóa nhầm dữ liệu lúc 2 giờ sáng, em truy thế nào?**
> Bảng `audit_log` ghi ai làm, làm gì, giá trị trước và sau, vào lúc nào. Xem ở trang "Nhật ký thao
> tác". **Giới hạn:** hiện chỉ ghi các thao tác nhạy cảm chứ chưa ghi toàn bộ, và chưa có cơ chế
> sao lưu tự động — đó là hai thứ cần bổ sung nếu chạy thật.

**C6. Web của em chịu được bao nhiêu người dùng cùng lúc?**
> Chưa đo. Muốn biết phải chạy thử tải bằng JMeter hoặc k6. Dự đoán nút thắt sẽ là số kết nối trong
> **connection pool** tới SQL Server và các truy vấn nạp danh sách sản phẩm.

**C7. Mật khẩu app Gmail và chuỗi kết nối DB em để đâu?**
> Trong `application.properties`. **Đây là điểm yếu nhóm biết rõ:** file này nằm trong Git nên từng
> có một app password bị lộ trong lịch sử commit, đã thu hồi và tạo mới. Làm đúng thì phải để trong
> **biến môi trường** hoặc một kho bí mật, và `application.properties` chỉ giữ giá trị mặc định cho
> môi trường phát triển.
>
> *(Trả lời thẳng như vậy tốt hơn nhiều so với giấu. Người chấm nhìn `git log` là ra.)*

**C8. Sao em không dùng microservice?**
> Vì bài toán không cần. Microservice giải quyết vấn đề **nhiều đội cùng phát triển một hệ thống
> lớn** và **cần mở rộng từng phần độc lập**. Ở đây một shop, ba người, một cơ sở dữ liệu — chia
> nhỏ ra chỉ tự thêm việc: phải xử lý gọi mạng giữa các dịch vụ, transaction phân tán, theo dõi lỗi
> xuyên dịch vụ. Kiến trúc **một khối nhưng phân tầng rõ** là lựa chọn đúng ở quy mô này.

**C9. Đoạn code nào trong dự án em thấy chưa ổn nhất?**
> Chọn sẵn một chỗ và nói thật. Gợi ý: `Product.specs/variants` để EAGER là một đánh đổi — biết là
> nạp thừa nhưng chuyển sang LAZY thì JSP ném `LazyInitializationException` do cấu hình Spring dồn
> hết vào servlet context. Đã thử chuyển hai lần và phải quay lại, có ghi chú lý do ngay trong
> `model/Product.java` và `config/WebInitializer.java`.
>
> *(Câu hỏi này là bẫy. Trả lời "không có chỗ nào" là mất điểm ngay.)*

**C10. Ba người chia việc thế nào? Ai làm phần nào?**
> Trả lời theo bảng phân vai đầu tài liệu. Nói rõ mỗi người phụ trách mảng nào, và **cả ba đều nắm
> phần nền tảng chung** để hỗ trợ nhau. Dùng Git với nhánh riêng, gộp về `main` sau khi chạy được.

---

# PHỤ LỤC — Danh mục file cần thuộc đường dẫn

| Cần chỉ khi được hỏi về | File |
|---|---|
| Cấu hình Spring, luồng request | `config/WebInitializer.java`, `config/AppConfig.java` |
| Bảo mật, phân quyền, CSRF | `config/SecurityConfig.java` |
| Luật tạo đơn | `service/OrderService.java` |
| Máy trạng thái đơn | `service/OrderService.java` → `LUONG_HOP_LE` |
| Xuất kho FIFO | `service/StockService.java` → `stockOutFIFO` |
| Trigger giữ tồn kho | `share.sql` (phần 5, cuối file) |
| Giá combo | `service/ComboService.java` → `chotGiaBo`, `phanBoGiamGia` |
| Chặn giá 0đ ở flash sale | `service/FlashSaleService.java` → `saveItems` |
| Chặn xóa tài khoản có dữ liệu | `service/UserService.java` → `deleteUser` |
| Chống CSRF cho link hành động | `static/js/post-link.js` |
| Lớp lỗi nghiệp vụ | `exception/LoiNghiepVu.java` |
| Test | `src/test/java/com/titangear/service/` — 6 lớp: `OrderServiceTest`, `StockServiceTest`, `ComboServiceTest`, `VoucherServiceTest`, `WarrantyServiceTest`, `RestockNotificationServiceTest` |
| Dựng lại toàn bộ DB | `share.sql` |
