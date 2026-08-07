/* =====================================================================
   TiTanGEAR - script tao lai TOAN BO co so du lieu
   Sinh truc tiep tu DB that, ngay 2026-08-03 15:56:04.202

   ---------------------------------------------------------------
   CACH CHAY
   ---------------------------------------------------------------
     1. Mo SQL Server Management Studio, ket noi vao SQL Server cua may minh
     2. File > Open > chon file nay
     3. Bam Execute (F5)

   KHONG can tao database truoc - script tu tao TITANGEAR_DB.
   Script CHAY LAI NHIEU LAN duoc: moi lan chay se xoa sach cai cu
   roi dung lai tu dau, nen lo tay chay 2 lan cung khong sao.

   ---------------------------------------------------------------
   SAU KHI CHAY XONG - noi ung dung vao DB
   ---------------------------------------------------------------
   Mo src/main/resources/application.properties va sua 3 dong:
     db.url=jdbc:sqlserver://localhost:1433;databaseName=TITANGEAR_DB;encrypt=false;trustServerCertificate=true
     db.username=<tai khoan SQL Server cua ban>
     db.password=<mat khau SQL Server cua ban>

   ---------------------------------------------------------------
   TAI KHOAN CO SAN (mat khau da ma hoa BCrypt, hoi chu du an de lay)
   ---------------------------------------------------------------
     admin@titanstore.com           ADMIN      
     warehouse@titanstore.com       WAREHOUSE  
     khachhang1@gmail.com           CUSTOMER   
     minhtuz5709@gmail.com          CUSTOMER   
     namph@gmail.com                CUSTOMER   
     tupmtv00386@gmail.com          CUSTOMER   

   ---------------------------------------------------------------
   LUU Y QUAN TRONG VE TON KHO
   ---------------------------------------------------------------
   Hai cot products.stock_quantity va product_variants.stock KHONG do
   code Java ghi vao. Chung do 3 TRIGGER trong script nay tu tinh lai
   moi khi co dong nhap kho (stock_in) hoac xuat kho (stock_out).
   Vi vay phan trigger duoc tao O CUOI FILE, sau khi da do xong du lieu -
   neu tao trigger truoc thi moi cau INSERT se kich hoat trigger va cong
   don sai so ton. Dung tu tay UPDATE hai cot nay.

   Thu tu cac phan trong file: bang -> du lieu -> khoa ngoai -> chi muc
                               -> trigger
   Tong cong 23 bang.
   ===================================================================== */

IF DB_ID('TITANGEAR_DB') IS NULL
    CREATE DATABASE TITANGEAR_DB;
GO
USE TITANGEAR_DB;
GO

/* ---------- 1. Xoa sach cai cu (de chay lai duoc nhieu lan) ---------- */
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N'ALTER TABLE [' + OBJECT_NAME(parent_object_id)
            + N'] DROP CONSTRAINT [' + name + N'];' + CHAR(10)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO
DROP TABLE IF EXISTS [audit_log];
DROP TABLE IF EXISTS [cart_items];
DROP TABLE IF EXISTS [categories];
DROP TABLE IF EXISTS [combo_items];
DROP TABLE IF EXISTS [combos];
DROP TABLE IF EXISTS [flash_sale_items];
DROP TABLE IF EXISTS [flash_sales];
DROP TABLE IF EXISTS [order_items];
DROP TABLE IF EXISTS [orders];
DROP TABLE IF EXISTS [product_lines];
DROP TABLE IF EXISTS [product_specs];
DROP TABLE IF EXISTS [product_variants];
DROP TABLE IF EXISTS [products];
DROP TABLE IF EXISTS [restock_notifications];
DROP TABLE IF EXISTS [reviews];
DROP TABLE IF EXISTS [stock_in];
DROP TABLE IF EXISTS [stock_out];
DROP TABLE IF EXISTS [system_settings];
DROP TABLE IF EXISTS [users];
DROP TABLE IF EXISTS [voucher_usages];
DROP TABLE IF EXISTS [vouchers];
DROP TABLE IF EXISTS [warranties];
DROP TABLE IF EXISTS [warranty_repairs];
GO

/* ---------- Bang: audit_log ---------- */
CREATE TABLE [audit_log] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [user_id] INT NULL,
    [user_email] NVARCHAR(255) NULL,
    [hanh_dong] NVARCHAR(50) NOT NULL,
    [doi_tuong] NVARCHAR(50) NULL,
    [doi_tuong_id] INT NULL,
    [gia_tri_cu] NVARCHAR(500) NULL,
    [gia_tri_moi] NVARCHAR(500) NULL,
    [mo_ta] NVARCHAR(500) NULL,
    [dia_chi_ip] NVARCHAR(45) NULL,
    [thoi_diem] DATETIME2(7) NOT NULL DEFAULT (getdate()),
    CONSTRAINT [PK__audit_lo__3213E83FC9C50759] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: cart_items ---------- */
CREATE TABLE [cart_items] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [user_id] INT NOT NULL,
    [product_id] INT NOT NULL,
    [quantity] INT NOT NULL DEFAULT ((1)),
    [added_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [variant_id] INT NULL,
    [combo_id] INT NULL,
    [combo_item_id] INT NULL,
    CONSTRAINT [PK__cart_ite__3213E83FECA5725E] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: categories ---------- */
CREATE TABLE [categories] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [name] NVARCHAR(255) NOT NULL,
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    CONSTRAINT [PK__categori__3213E83FD6F55F49] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: combo_items ---------- */
CREATE TABLE [combo_items] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [combo_id] INT NOT NULL,
    [product_id] INT NOT NULL,
    [quantity] INT NOT NULL DEFAULT ((1)),
    [variant_id] INT NULL,
    CONSTRAINT [PK__combo_it__3213E83F9397453D] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ComboItems] UNIQUE ([combo_id], [product_id])
);
GO

/* ---------- Bang: combos ---------- */
CREATE TABLE [combos] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [tag] NVARCHAR(50) NULL,
    [description] NVARCHAR(500) NULL,
    [discount_amount] DECIMAL(18,2) NOT NULL DEFAULT ((0)),
    [accent_color] VARCHAR(7) NULL,
    [is_active] BIT NULL DEFAULT ((1)),
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    CONSTRAINT [PK__combos__3213E83F13685499] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: flash_sale_items ---------- */
CREATE TABLE [flash_sale_items] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [flash_sale_id] INT NOT NULL,
    [product_id] INT NOT NULL,
    [discount_type] NVARCHAR(10) NOT NULL,
    [discount_value] DECIMAL(18,2) NOT NULL,
    CONSTRAINT [PK__flash_sa__3213E83FB6A841AB] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_FlashSaleItems] UNIQUE ([flash_sale_id], [product_id]),
    CONSTRAINT [CHK_FlashSaleItems_DiscountType] CHECK ([discount_type]=N'AMOUNT' OR [discount_type]=N'PERCENT'),
    CONSTRAINT [CHK_FlashSaleItems_DiscountValue] CHECK ([discount_type]=N'PERCENT' AND [discount_value]>(0) AND [discount_value]<=(100) OR [discount_type]=N'AMOUNT' AND [discount_value]>(0))
);
GO

/* ---------- Bang: flash_sales ---------- */
CREATE TABLE [flash_sales] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [name] NVARCHAR(255) NOT NULL,
    [display_type] NVARCHAR(20) NOT NULL,
    [start_at] DATETIME2(7) NOT NULL,
    [end_at] DATETIME2(7) NOT NULL,
    [is_active] BIT NULL DEFAULT ((1)),
    [display_order] INT NULL DEFAULT ((0)),
    [banner_image_url] NVARCHAR(500) NULL,
    [banner_title] NVARCHAR(255) NULL,
    [banner_subtitle] NVARCHAR(500) NULL,
    [banner_cta_text] NVARCHAR(100) NULL,
    [banner_cta_link] NVARCHAR(500) NULL,
    [text_bar_content] NVARCHAR(500) NULL,
    [created_by] INT NOT NULL,
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    CONSTRAINT [PK__flash_sa__3213E83FACF0E266] PRIMARY KEY ([id]),
    CONSTRAINT [CHK_FlashSales_DisplayType] CHECK ([display_type]=N'TEXT_BAR' OR [display_type]=N'BANNER'),
    CONSTRAINT [CHK_FlashSales_TimeRange] CHECK ([end_at]>[start_at]),
    CONSTRAINT [CHK_FlashSales_FieldsByType] CHECK ([display_type]=N'BANNER' AND [banner_image_url] IS NOT NULL AND [banner_title] IS NOT NULL AND [text_bar_content] IS NULL OR [display_type]=N'TEXT_BAR' AND [text_bar_content] IS NOT NULL AND [banner_image_url] IS NULL AND [banner_title] IS NULL)
);
GO

/* ---------- Bang: order_items ---------- */
CREATE TABLE [order_items] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [order_id] INT NOT NULL,
    [product_id] INT NOT NULL,
    [product_name] NVARCHAR(255) NULL,
    [unit_price] DECIMAL(18,2) NOT NULL,
    [quantity] INT NOT NULL,
    [line_total] DECIMAL(18,2) NOT NULL,
    [variant_id] INT NULL,
    [combo_id] INT NULL,
    CONSTRAINT [PK__order_it__3213E83F2CC63F69] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: orders ---------- */
CREATE TABLE [orders] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [user_id] INT NOT NULL,
    [receiver_name] NVARCHAR(255) NOT NULL,
    [receiver_phone] VARCHAR(20) NOT NULL,
    [shipping_address] NVARCHAR(500) NOT NULL,
    [total_amount] DECIMAL(18,2) NOT NULL,
    [status] NVARCHAR(50) NULL DEFAULT (N'PENDING'),
    [payment_method] NVARCHAR(100) NULL,
    [note] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [updated_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [is_paid] BIT NOT NULL DEFAULT ((0)),
    [voucher_id] INT NULL,
    [discount_amount] DECIMAL(18,2) NOT NULL DEFAULT ((0)),
    [shipping_fee] DECIMAL(18,2) NOT NULL DEFAULT ((0)),
    [province] NVARCHAR(100) NULL,
    CONSTRAINT [PK__orders__3213E83F3E8251F2] PRIMARY KEY ([id]),
    CONSTRAINT [CHK_Orders_Status] CHECK ([status]=N'CANCELLED' OR [status]=N'COMPLETED' OR [status]=N'SHIPPING' OR [status]=N'AWAITING_STOCK' OR [status]=N'PENDING')
);
GO

/* ---------- Bang: product_lines ---------- */
CREATE TABLE [product_lines] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    CONSTRAINT [PK__product___3213E83F4ADA2C70] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: product_specs ---------- */
CREATE TABLE [product_specs] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [product_id] INT NOT NULL,
    [spec_name] NVARCHAR(100) NOT NULL,
    [spec_value] NVARCHAR(255) NOT NULL,
    CONSTRAINT [PK__product___3213E83F22AC77BA] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: product_variants ---------- */
CREATE TABLE [product_variants] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [product_id] INT NOT NULL,
    [name] NVARCHAR(100) NULL,
    [color] NVARCHAR(50) NULL,
    [rgb_code] NVARCHAR(10) NULL,
    [image_url] NVARCHAR(255) NULL,
    [price] DECIMAL(18,2) NOT NULL,
    [stock] INT NULL DEFAULT ((0)),
    [is_active] BIT NULL DEFAULT ((1)),
    CONSTRAINT [PK__product___3213E83F5750B287] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: products ---------- */
CREATE TABLE [products] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [category_id] INT NOT NULL,
    [name] NVARCHAR(255) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [price] DECIMAL(18,2) NOT NULL,
    [stock_quantity] INT NULL DEFAULT ((0)),
    [image_url] VARCHAR(500) NULL,
    [is_active] BIT NULL DEFAULT ((1)),
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [updated_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [switch_type] NVARCHAR(30) NULL,
    [weight_group] NVARCHAR(20) NULL,
    [connectivity] NVARCHAR(20) NULL,
    [warranty_months] INT NULL,
    [line_id] INT NULL,
    CONSTRAINT [PK__products__3213E83FD50E2D20] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: restock_notifications ---------- */
CREATE TABLE [restock_notifications] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [product_id] INT NOT NULL,
    [email] NVARCHAR(255) NOT NULL,
    [is_notified] BIT NOT NULL DEFAULT ((0)),
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [variant_id] INT NULL,
    CONSTRAINT [PK__restock___3213E83F4CDFE210] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: reviews ---------- */
CREATE TABLE [reviews] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [product_id] INT NOT NULL,
    [user_id] INT NOT NULL,
    [rating] INT NOT NULL,
    [comment] NVARCHAR(2000) NULL,
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [updated_at] DATETIME2(7) NULL DEFAULT (getdate()),
    CONSTRAINT [PK__reviews__3213E83FB17D05A4] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_Reviews_UserProduct] UNIQUE ([user_id], [product_id]),
    CONSTRAINT [CHK_Reviews_Rating] CHECK ([rating]>=(1) AND [rating]<=(5))
);
GO

/* ---------- Bang: stock_in ---------- */
CREATE TABLE [stock_in] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [product_id] INT NOT NULL,
    [quantity] INT NOT NULL,
    [import_price] DECIMAL(18,2) NOT NULL,
    [supplier] NVARCHAR(255) NULL,
    [note] NVARCHAR(MAX) NULL,
    [imported_by] INT NOT NULL,
    [imported_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [remaining_quantity] INT NOT NULL,
    [received_at] DATETIME2(7) NULL,
    [checked_at] DATETIME2(7) NULL,
    [variant_id] INT NULL,
    [khu] NVARCHAR(1) NULL,
    [ke] INT NULL,
    CONSTRAINT [PK__stock_im__3213E83F12D62289] PRIMARY KEY ([id]),
    CONSTRAINT [CHK_remaining_quantity] CHECK ([remaining_quantity]>=(0)),
    CONSTRAINT [CHK_RemainingNotExceedQuantity] CHECK ([remaining_quantity]<=[quantity])
);
GO

/* ---------- Bang: stock_out ---------- */
CREATE TABLE [stock_out] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [exported_by] INT NOT NULL,
    [exported_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [note] NVARCHAR(MAX) NULL,
    [import_cost] DECIMAL(18,2) NULL,
    [order_item_id] INT NOT NULL,
    [stock_in_id] INT NOT NULL,
    [quantity] INT NOT NULL,
    [is_returned] BIT NOT NULL DEFAULT ((0)),
    [returned_at] DATETIME2(7) NULL,
    CONSTRAINT [PK__stock_ex__3213E83FC51EE0E5] PRIMARY KEY ([id]),
    CONSTRAINT [CHK_Exports_Quantity] CHECK ([quantity]>(0))
);
GO

/* ---------- Bang: system_settings ---------- */
CREATE TABLE [system_settings] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [setting_key] NVARCHAR(100) NOT NULL,
    [setting_value] NVARCHAR(255) NOT NULL,
    [description] NVARCHAR(500) NULL,
    CONSTRAINT [PK__system_s__3213E83FDE1FBF6D] PRIMARY KEY ([id]),
    CONSTRAINT [UQ__system_s__0DFAC4279B202630] UNIQUE ([setting_key])
);
GO

/* ---------- Bang: users ---------- */
CREATE TABLE [users] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [full_name] NVARCHAR(255) NOT NULL,
    [email] VARCHAR(150) NOT NULL,
    [phone] VARCHAR(20) NULL,
    [password_hash] VARCHAR(255) NOT NULL,
    [role] NVARCHAR(50) NULL DEFAULT (N'CUSTOMER'),
    [address] NVARCHAR(500) NULL,
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [is_active] BIT NOT NULL DEFAULT ((1)),
    CONSTRAINT [PK__users__3213E83F4CD71847] PRIMARY KEY ([id]),
    CONSTRAINT [UQ__users__AB6E6164E8F0FADD] UNIQUE ([email]),
    CONSTRAINT [CHK_Users_Role] CHECK ([role]=N'WAREHOUSE' OR [role]=N'CUSTOMER' OR [role]=N'ADMIN')
);
GO

/* ---------- Bang: voucher_usages ---------- */
CREATE TABLE [voucher_usages] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [voucher_id] INT NOT NULL,
    [user_id] INT NOT NULL,
    [order_id] INT NULL,
    [discount_amount] DECIMAL(18,2) NOT NULL,
    [used_at] DATETIME2(7) NULL DEFAULT (getdate()),
    CONSTRAINT [PK__voucher___3213E83F1C7A0DC6] PRIMARY KEY ([id])
);
GO

/* ---------- Bang: vouchers ---------- */
CREATE TABLE [vouchers] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [code] NVARCHAR(50) NOT NULL,
    [description] NVARCHAR(255) NULL,
    [discount_type] NVARCHAR(20) NOT NULL,
    [discount_value] DECIMAL(18,2) NOT NULL,
    [min_order_amount] DECIMAL(18,2) NULL,
    [max_discount_amount] DECIMAL(18,2) NULL,
    [start_at] DATETIME2(7) NULL,
    [end_at] DATETIME2(7) NULL,
    [usage_limit] INT NULL,
    [used_count] INT NOT NULL DEFAULT ((0)),
    [once_per_user] BIT NOT NULL DEFAULT ((1)),
    [is_active] BIT NOT NULL DEFAULT ((1)),
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    [combo_id] INT NULL,
    [chi_don_co_combo] BIT NOT NULL DEFAULT ((0)),
    CONSTRAINT [PK__vouchers__3213E83F8CDEFE2B] PRIMARY KEY ([id]),
    CONSTRAINT [UQ__vouchers__357D4CF9D6133A4A] UNIQUE ([code]),
    CONSTRAINT [CHK_Voucher_Type] CHECK ([discount_type]=N'AMOUNT' OR [discount_type]=N'PERCENT'),
    CONSTRAINT [CHK_Voucher_Value] CHECK ([discount_value]>(0))
);
GO

/* ---------- Bang: warranties ---------- */
CREATE TABLE [warranties] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [serial_no] NVARCHAR(30) NOT NULL,
    [order_item_id] INT NOT NULL,
    [product_id] INT NOT NULL,
    [user_id] INT NOT NULL,
    [start_date] DATE NOT NULL,
    [end_date] DATE NOT NULL,
    [note] NVARCHAR(500) NULL,
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    CONSTRAINT [PK__warranti__3213E83FD59D910F] PRIMARY KEY ([id]),
    CONSTRAINT [UQ__warranti__E5458192F5082F8A] UNIQUE ([serial_no])
);
GO

/* ---------- Bang: warranty_repairs ---------- */
CREATE TABLE [warranty_repairs] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [warranty_id] INT NOT NULL,
    [noi_dung] NVARCHAR(500) NOT NULL,
    [trang_thai] NVARCHAR(30) NOT NULL,
    [created_at] DATETIME2(7) NULL DEFAULT (getdate()),
    CONSTRAINT [PK__warranty__3213E83F6874B933] PRIMARY KEY ([id])
);
GO

/* ---------- 2. Du lieu ---------- */
/* Do du lieu TRUOC khi tao trigger: neu tao trigger truoc thi moi cau
   INSERT se kich hoat trigger va tinh lai ton kho, lam sai so da co san. */

-- audit_log (1 dong)
SET IDENTITY_INSERT [audit_log] ON;
INSERT INTO [audit_log] ([id], [user_id], [user_email], [hanh_dong], [doi_tuong], [doi_tuong_id], [gia_tri_cu], [gia_tri_moi], [mo_ta], [dia_chi_ip], [thoi_diem]) VALUES
(1, 1, N'admin@titanstore.com', N'SUA_GIA', N'products', 2, N'770000.00', N'790000', N'Đổi giá "Chuột ATK X1 Pro Max"', N'0:0:0:0:0:0:0:1', N'2026-08-02 01:48:13.6948712');
SET IDENTITY_INSERT [audit_log] OFF;
GO

-- cart_items (2 dong)
SET IDENTITY_INSERT [cart_items] ON;
INSERT INTO [cart_items] ([id], [user_id], [product_id], [quantity], [added_at], [variant_id], [combo_id], [combo_item_id]) VALUES
(1055, 3, 3, 1, N'2026-08-01 00:19:51.1850639', NULL, NULL, NULL),
(1084, 1, 1, 1, N'2026-08-03 10:36:21.8315543', 7, NULL, NULL);
SET IDENTITY_INSERT [cart_items] OFF;
GO

-- categories (3 dong)
SET IDENTITY_INSERT [categories] ON;
INSERT INTO [categories] ([id], [name], [created_at]) VALUES
(1, N'Chuột Gaming', N'2026-06-02 21:22:20.3766667'),
(2, N'Bàn Phím Cơ', N'2026-06-02 21:22:20.3766667'),
(3, N'Tai Nghe Gaming', N'2026-06-02 21:22:20.3766667');
SET IDENTITY_INSERT [categories] OFF;
GO

-- combo_items (10 dong)
SET IDENTITY_INSERT [combo_items] ON;
INSERT INTO [combo_items] ([id], [combo_id], [product_id], [quantity], [variant_id]) VALUES
(9, 2, 1, 1, 3),
(10, 2, 3, 1, NULL),
(11, 3, 1, 1, 7),
(12, 3, 3, 1, NULL),
(13, 4, 1, 1, 7),
(14, 4, 3, 1, NULL),
(15, 4, 5, 1, NULL),
(16, 1, 9, 1, NULL),
(17, 1, 3, 1, NULL),
(18, 1, 5, 1, NULL);
SET IDENTITY_INSERT [combo_items] OFF;
GO

-- combos (4 dong)
SET IDENTITY_INSERT [combos] ON;
INSERT INTO [combos] ([id], [name], [tag], [description], [discount_amount], [accent_color], [is_active], [created_at]) VALUES
(1, N'Combo Aim Lab', N'FPS TRY-HARD', N'Chuột siêu nhẹ + bàn phím Rapid Trigger — bộ đôi cho Valorant, CS2.', 350000.00, N'#1B49FF', 1, N'2026-08-01 11:59:34.38'),
(2, N'Combo Silent Work', N'VĂN PHÒNG', N'Gõ êm, chuột form vừa tay — làm 8 tiếng không mỏi cổ tay.', 280000.00, N'#7A5CC7', 1, N'2026-08-01 11:59:34.3833333'),
(3, N'Combo Kiem Thu', N'KIEM THU', N'', 150000.00, N'#1B49FF', 0, N'2026-08-01 19:07:21.5532852'),
(4, N'Combo Kiem Thu', N'KIEM THU', N'', 150000.00, N'#1B49FF', 0, N'2026-08-01 19:08:58.1864579');
SET IDENTITY_INSERT [combos] OFF;
GO

-- flash_sale_items (1 dong)
SET IDENTITY_INSERT [flash_sale_items] ON;
INSERT INTO [flash_sale_items] ([id], [flash_sale_id], [product_id], [discount_type], [discount_value]) VALUES
(2, 3, 1, N'PERCENT', 20.00);
SET IDENTITY_INSERT [flash_sale_items] OFF;
GO

-- flash_sales (1 dong)
SET IDENTITY_INSERT [flash_sales] ON;
INSERT INTO [flash_sales] ([id], [name], [display_type], [start_at], [end_at], [is_active], [display_order], [banner_image_url], [banner_title], [banner_subtitle], [banner_cta_text], [banner_cta_link], [text_bar_content], [created_by], [created_at]) VALUES
(3, N'Flash Sale Cuối Tuần Tháng 7', N'BANNER', N'2026-07-08 21:02:00.0', N'2026-07-30 21:02:00.0', 1, 0, N'1783519395963_PC_11f6ce48-c781-455d-9024-480d7799cd87.webp', N'atk', N'111', N'mua', N'/products/1', NULL, 1, N'2026-07-08 21:03:16.022685');
SET IDENTITY_INSERT [flash_sales] OFF;
GO

-- order_items (45 dong)
SET IDENTITY_INSERT [order_items] ON;
INSERT INTO [order_items] ([id], [order_id], [product_id], [product_name], [unit_price], [quantity], [line_total], [variant_id], [combo_id]) VALUES
(1, 1, 1, N'Chuột ATK F1 Ultimate', 1450000.00, 1, 1450000.00, NULL, NULL),
(2, 2, 4, N'Bàn phím Cơ ATK V75 Pro', 1850000.00, 2, 3700000.00, NULL, NULL),
(3, 3, 2, N'Chuột ATK X1 Pro Max', 1350000.00, 1, 1350000.00, NULL, NULL),
(4, 4, 1, N'Chuột ATK F1 Ultimate', 1450000.00, 1, 1450000.00, NULL, NULL),
(5, 5, 5, N'Tai nghe ATK Mercury I Wireless', 950000.00, 1, 950000.00, NULL, NULL),
(6, 6, 2, N'Chuột ATK X1 Pro Max', 1350000.00, 1, 1350000.00, NULL, NULL),
(7, 7, 2, N'Chuột ATK X1 Pro Max', 1350000.00, 1, 1350000.00, NULL, NULL),
(8, 8, 4, N'Bàn phím Cơ ATK V75 Pro', 1850000.00, 2, 3700000.00, NULL, NULL),
(9, 9, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 5, 7250100.00, NULL, NULL),
(10, 9, 10, N'Bàn phím ATK RS6+ Aluminum Magnetic', 2800000.00, 1, 2800000.00, NULL, NULL),
(11, 9, 2, N'Chuột ATK X1 Pro Max', 1350000.00, 1, 1350000.00, NULL, NULL),
(12, 10, 2, N'Chuột ATK X1 Pro Max', 1350000.00, 1, 1350000.00, NULL, NULL),
(13, 10, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, NULL, NULL),
(14, 11, 2, N'Chuột ATK X1 Pro Max', 1350000.00, 1, 1350000.00, NULL, NULL),
(15, 12, 10, N'Bàn phím ATK RS6+ Aluminum Magnetic', 2800000.00, 9, 25200000.00, NULL, NULL),
(16, 13, 11, N'Chuột ATK F1 Ultimate11', 20000.00, 1, 20000.00, NULL, NULL),
(17, 14, 11, N'Chuột ATK F1 Ultimate11', 20000.00, 1, 20000.00, NULL, NULL),
(18, 15, 11, N'Chuột ATK F1 Ultimate11', 20000.00, 1, 20000.00, NULL, NULL),
(19, 16, 11, N'Chuột ATK F1 Ultimate11', 20000.00, 1, 20000.00, NULL, NULL),
(20, 17, 11, N'Chuột ATK F1 Ultimate11', 20000.00, 1, 20000.00, NULL, NULL),
(21, 18, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, NULL, NULL),
(1021, 1018, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL),
(1022, 1019, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL),
(1023, 1020, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, NULL, NULL),
(1024, 1021, 2, N'Chuột ATK X1 Pro Max', 1350000.00, 1, 1350000.00, NULL, NULL),
(1025, 1022, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL),
(1026, 1023, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL),
(1027, 1024, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL),
(1028, 1025, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, 4, NULL),
(1029, 1026, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL),
(1030, 1027, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL),
(1031, 1028, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL),
(1032, 1029, 3, N'Bàn phím Từ Tính ATK68 v2', 2100000.00, 1, 2100000.00, NULL, NULL),
(1033, 1030, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, 3, NULL),
(1034, 1031, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, 4, NULL),
(1035, 1032, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, 4, NULL),
(1036, 1033, 9, N'Chuột ATK Dragonfly A9 Wireless', 1650000.00, 2, 3300000.00, NULL, NULL),
(1037, 1034, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, 4, NULL),
(1038, 1035, 3, N'Bàn phím Từ Tính ATK68 v2', 2100000.00, 1, 2100000.00, NULL, NULL),
(1039, 1036, 1, N'Chuột ATK F1 Ultimate', 1160016.00, 2, 2320032.00, 4, NULL),
(1040, 1037, 2, N'Chuột ATK X1 Pro Max', 1350000.00, 1, 1350000.00, 5, NULL),
(1041, 1038, 1, N'Chuột ATK F1 Ultimate', 1450020.00, 1, 1450020.00, 3, NULL),
(1042, 1039, 16, N'Chuột ATK F1 Ultimate', 1335634.00, 1, 1335634.00, 38, 2),
(1043, 1039, 3, N'Bàn phím Từ Tính ATK68 v2', 1934366.00, 1, 1934366.00, NULL, 2),
(1044, 1041, 11, N'Chuột ATK F1 Ultimate11222', 20000.00, 1, 20000.00, NULL, NULL);
SET IDENTITY_INSERT [order_items] OFF;
GO

-- orders (41 dong)
SET IDENTITY_INSERT [orders] ON;
INSERT INTO [orders] ([id], [user_id], [receiver_name], [receiver_phone], [shipping_address], [total_amount], [status], [payment_method], [note], [created_at], [updated_at], [is_paid], [voucher_id], [discount_amount], [shipping_fee], [province]) VALUES
(1, 3, N'Lê Minh Khách', N'0905111222', N'123 Đường Láng, Đống Đa, Hà Nội', 1450000.00, N'COMPLETED', N'COD', N'Giao giờ hành chính', N'2026-06-02 21:22:20.38', N'2026-06-11 09:51:22.6460341', 0, NULL, 0.00, 0.00, NULL),
(2, 4, N'Phạm Hải Nam', N'0934555666', N'456 Lê Lợi, Quận 1, TP. HCM', 3700000.00, N'COMPLETED', N'VNPAY', N'Hàng tặng sinh nhật cần gấp', N'2026-06-02 21:22:20.3833333', N'2026-06-04 20:50:54.5642775', 0, NULL, 0.00, 0.00, NULL),
(3, 3, N'Lê Minh Khách', N'0905111222', N'123 Đường Láng, Đống Đa, Hà Nội', 1350000.00, N'CANCELLED', N'VNPAY', N'khong co gi', N'2026-06-09 21:02:34.9503778', N'2026-07-23 20:52:01.218638', 0, NULL, 0.00, 0.00, NULL),
(4, 3, N'Lê Minh Khách', N'0905111222', N'123 Đường Láng, Đống Đa, Hà Nội', 1450000.00, N'SHIPPING', N'COD', N'', N'2026-06-09 21:03:31.9311038', N'2026-06-11 07:53:20.6714935', 0, NULL, 0.00, 0.00, NULL),
(5, 3, N'Lê Minh Khách', N'0905111222', N'123 Đường Láng, Đống Đa, Hà Nội', 950000.00, N'COMPLETED', N'VNPAY', N'', N'2026-06-09 21:22:11.9588845', N'2026-06-11 09:51:29.1465629', 0, NULL, 0.00, 0.00, NULL),
(6, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 1350000.00, N'COMPLETED', N'VNPAY', N'', N'2026-06-11 10:43:40.1550559', N'2026-06-11 10:54:05.4127232', 0, NULL, 0.00, 0.00, NULL),
(7, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 1350000.00, N'CANCELLED', N'VNPAY', N'', N'2026-06-11 10:48:15.2651', N'2026-06-11 10:54:17.9892071', 0, NULL, 0.00, 0.00, NULL),
(8, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 3700000.00, N'COMPLETED', N'VNPAY', N'', N'2026-06-11 11:36:13.8937083', N'2026-06-11 11:39:25.7603247', 0, NULL, 0.00, 0.00, NULL),
(9, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 11400100.00, N'COMPLETED', N'VNPAY', N'', N'2026-06-16 09:21:30.6398904', N'2026-07-24 15:24:43.6925323', 0, NULL, 0.00, 0.00, NULL),
(10, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 2800020.00, N'COMPLETED', N'COD', N'', N'2026-06-16 09:43:58.3048944', N'2026-06-16 09:45:35.1897225', 0, NULL, 0.00, 0.00, NULL),
(11, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 1350000.00, N'CANCELLED', N'VNPAY', N'', N'2026-06-16 21:27:27.7335482', N'2026-07-23 20:51:59.2126322', 0, NULL, 0.00, 0.00, NULL),
(12, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 25200000.00, N'AWAITING_STOCK', N'VNPAY', N'', N'2026-06-16 21:29:50.9590454', N'2026-07-24 15:25:22.9512771', 1, NULL, 0.00, 0.00, NULL),
(13, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 20000.00, N'PENDING', N'VNPAY', N'', N'2026-06-16 21:59:36.3387553', N'2026-06-16 22:00:03.2694907', 1, NULL, 0.00, 0.00, NULL),
(14, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 20000.00, N'CANCELLED', N'VNPAY', N'', N'2026-06-16 22:00:20.3313837', N'2026-08-02 01:00:43.7909345', 0, NULL, 0.00, 0.00, NULL),
(15, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 20000.00, N'CANCELLED', N'VNPAY', N'', N'2026-06-16 22:41:17.9270225', N'2026-08-02 01:00:44.1039046', 0, NULL, 0.00, 0.00, NULL),
(16, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 20000.00, N'CANCELLED', N'VNPAY', N'', N'2026-06-16 22:45:11.6464781', N'2026-07-23 20:52:08.7709082', 1, NULL, 0.00, 0.00, NULL),
(17, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 20000.00, N'CANCELLED', N'VNPAY', N'', N'2026-06-16 23:01:22.5689105', N'2026-07-23 20:52:10.9441403', 1, NULL, 0.00, 0.00, NULL),
(18, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 1450020.00, N'COMPLETED', N'COD', N'', N'2026-06-17 07:40:16.7825673', N'2026-06-17 07:42:13.3876139', 1, NULL, 0.00, 0.00, NULL),
(1018, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 20000.00, N'CANCELLED', N'VNPAY', N'', N'2026-06-26 11:40:07.5386562', N'2026-07-23 20:52:06.9575137', 0, NULL, 0.00, 0.00, NULL),
(1019, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 20000.00, N'CANCELLED', N'VNPAY', N'', N'2026-06-26 11:42:55.309846', N'2026-07-23 20:52:05.4652279', 0, NULL, 0.00, 0.00, NULL),
(1020, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 1450020.00, N'CANCELLED', N'COD', N'', N'2026-06-28 11:03:15.4947814', N'2026-07-23 20:51:27.9783655', 1, NULL, 0.00, 0.00, NULL),
(1021, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 1350000.00, N'SHIPPING', N'COD', N'', N'2026-07-13 20:19:02.5913764', N'2026-07-13 20:19:12.0644944', 1, NULL, 0.00, 0.00, NULL),
(1022, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 20000.00, N'CANCELLED', N'VNPAY', N'', N'2026-07-13 21:39:44.1324353', N'2026-08-02 01:00:44.1883792', 0, NULL, 0.00, 0.00, NULL),
(1023, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 20000.00, N'COMPLETED', N'VNPAY', N'', N'2026-07-13 21:48:53.0762656', N'2026-07-24 15:25:32.970534', 1, NULL, 0.00, 0.00, NULL),
(1024, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 20000.00, N'COMPLETED', N'VNPAY', N'', N'2026-07-15 10:01:40.0593653', N'2026-07-15 10:06:02.7429571', 1, NULL, 0.00, 0.00, NULL),
(1025, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 1450020.00, N'COMPLETED', N'COD', N'', N'2026-07-15 10:07:27.354649', N'2026-07-15 10:07:39.2548981', 1, NULL, 0.00, 0.00, NULL),
(1026, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 20000.00, N'CANCELLED', N'COD', N'', N'2026-07-23 20:52:42.4060754', N'2026-07-23 20:52:48.7943328', 0, NULL, 0.00, 0.00, NULL),
(1027, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 20000.00, N'CANCELLED', N'COD', N'', N'2026-07-23 21:03:58.8762911', N'2026-07-23 21:04:31.2708263', 0, NULL, 0.00, 0.00, NULL),
(1028, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 20000.00, N'CANCELLED', N'VNPAY', N'', N'2026-07-23 21:04:41.9257252', N'2026-07-23 21:19:09.691184', 0, NULL, 0.00, 0.00, NULL),
(1029, 3, N'A du anh Hai', N'0905111222', N'123 Phu Hoa, TP.HCM', 2100000.00, N'CANCELLED', N'COD', N'', N'2026-07-23 21:18:52.063535', N'2026-07-23 21:19:07.9794315', 0, NULL, 0.00, 0.00, NULL),
(1030, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 1450020.00, N'COMPLETED', N'COD', N'', N'2026-07-24 15:25:58.0171371', N'2026-07-24 15:26:26.9336349', 1, NULL, 0.00, 0.00, NULL),
(1031, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 1450020.00, N'CANCELLED', N'COD', N'', N'2026-07-24 20:24:11.1444786', N'2026-07-26 17:28:16.0859369', 0, NULL, 0.00, 0.00, NULL),
(1032, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 1350020.00, N'CANCELLED', N'COD', N'', N'2026-07-26 20:40:18.9408624', N'2026-07-27 09:56:23.2067054', 0, 1, 100000.00, 0.00, NULL),
(1033, 1, N'Test COD 2', N'0912345678', N'42 Nguyen Van Tiet', 3300000.00, N'CANCELLED', N'COD', N'', N'2026-07-26 20:42:16.31628', N'2026-07-27 09:56:16.3886996', 0, NULL, 0.00, 0.00, NULL),
(1034, 1, N'Test VNPAY', N'0912345678', N'42 NVT', 1450020.00, N'CANCELLED', N'VNPAY', NULL, N'2026-07-26 20:43:32.8795606', N'2026-08-01 10:30:57.648464', 1, NULL, 0.00, 0.00, NULL),
(1035, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 1680000.00, N'PENDING', N'COD', N'', N'2026-07-27 10:04:30.4426172', N'2026-07-27 10:04:30.4426172', 0, 2, 420000.00, 0.00, NULL),
(1036, 1, N'Test Bao Hanh', N'0912345678', N'42 NVT', 2320032.00, N'COMPLETED', N'VNPAY', NULL, N'2026-07-29 21:45:11.626208', N'2026-08-01 10:31:00.2271545', 1, NULL, 0.00, 0.00, NULL),
(1037, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 1350000.00, N'CANCELLED', N'COD', N'', N'2026-08-01 00:32:46.3885395', N'2026-08-01 20:27:10.1912982', 0, NULL, 0.00, 0.00, NULL),
(1038, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 1450020.00, N'COMPLETED', N'VNPAY', N'', N'2026-08-01 00:41:34.1452978', N'2026-08-01 10:30:46.4689051', 1, NULL, 0.00, 0.00, NULL),
(1039, 1, N'Nguyễn Văn Admin', N'0912345678', N'42 Nguyen Van Tiet, TP.HCM', 3270000.00, N'CANCELLED', N'VNPAY', N'DON KIEM THU COMBO - se huy', N'2026-08-01 19:10:29.5931708', N'2026-08-01 19:11:32.3332105', 0, NULL, 0.00, 0.00, NULL),
(1041, 1, N'Nguyen Van Test', N'0912345678', N'42 Nguyen Van Tiet, Phuong Phu Cuong, Thu Dau Mot', 40000.00, N'PENDING', N'COD', N'KIEM THU PHI SHIP', N'2026-08-02 00:01:27.2642247', N'2026-08-02 00:01:27.2642247', 0, NULL, 0.00, 20000.00, N'TP. Hồ Chí Minh');
SET IDENTITY_INSERT [orders] OFF;
GO

-- product_lines (4 dong)
SET IDENTITY_INSERT [product_lines] ON;
INSERT INTO [product_lines] ([id], [name]) VALUES
(1, N'ATK Blazing Sky F1'),
(2, N'ATK Blazing Sky A9'),
(3, N'Chuột ATK X1'),
(4, N'ATK Blazing Sky F1 V2 Series Esports Wireless Mouse');
SET IDENTITY_INSERT [product_lines] OFF;
GO

-- product_specs (84 dong)
SET IDENTITY_INSERT [product_specs] ON;
INSERT INTO [product_specs] ([id], [product_id], [spec_name], [spec_value]) VALUES
(6, 3, N'Loại Switch', N'Magnetic Switch (Từ tính)'),
(7, 3, N'Tính năng độc quyền', N'Rapid Trigger'),
(8, 3, N'Layout', N'68%'),
(11, 5, N'Kết nối', N'Wireless 2.4G / Bluetooth / Dây Type-C'),
(12, 6, N'Layout', N'65%'),
(13, 6, N'Loại Switch', N'Hall Effect (Từ tính)'),
(14, 6, N'Tính năng', N'Rapid Trigger'),
(15, 6, N'Kết nối', N'Wireless 2.4G / Bluetooth / Dây'),
(21, 4, N'Layout', N'75%'),
(22, 4, N'Kiểu Gắn', N'Gasket Mount'),
(23, 7, N'Kết nối', N'Wireless 2.4G / Bluetooth / Dây Type-C'),
(24, 7, N'Âm thanh', N'Surround 7.1'),
(25, 7, N'Driver', N'40mm'),
(26, 7, N'Micro', N'Có thể tháo rời'),
(27, 8, N'Loại', N'In-ear'),
(28, 8, N'Chip âm thanh', N'DSP'),
(29, 8, N'Kết nối', N'3.5mm / Type-C'),
(30, 8, N'Driver', N'10mm'),
(36, 10, N'Vỏ máy', N'Nhôm nguyên khối'),
(37, 10, N'Loại Switch', N'Magnetic Switch (Từ tính)'),
(38, 10, N'Tính năng', N'Rapid Trigger'),
(39, 10, N'Layout', N'65%'),
(40, 10, N'Kết nối', N'Wireless 2.4G / Bluetooth / Dây Type-C'),
(41, 10, N'Kiểu gắn', N'Top Mount'),
(49, 11, N'màu', N'đen'),
(50, 11, N'Trọng lượng', N'38g'),
(1112, 9, N'Trọng lượng', N'42g'),
(1113, 9, N'Mắt đọc', N'PAW3395'),
(1114, 9, N'Kết nối', N'Wireless 2.4G / Bluetooth / Dây'),
(1115, 9, N'Polling Rate', N'4000Hz'),
(1116, 9, N'Pin', N'80 giờ'),
(1128, 12, N'Trọng lượng', N'54g'),
(1129, 12, N'Kích thước', N'118.2mm x 62.4mm x 38.8mm'),
(1130, 12, N'Hình dạng', N'Đối xứng'),
(1131, 12, N'Best for Hand Size', N'Small-to-Medium Hands'),
(1132, 12, N'Cảm biến', N'PAW3395 Ultra'),
(1133, 13, N'Cảm biến', N'PAW3950 Ultra'),
(1134, 13, N'Trọng lượng', N'39g'),
(1135, 13, N'Kích thước', N'118.2mm x 62.4mm x 38.8mm'),
(1136, 13, N'Pin', N'300mAh'),
(1137, 13, N'Thời lượng pin', N'600 Hours (1000Hz)'),
(1138, 13, N'Kết nối', N'Wired / 2.4GHz'),
(1145, 1, N'Cảm biến', N'PixArt PAW3950'),
(1146, 1, N'DPI tối đa', N'36.000 DPI'),
(1147, 1, N'Tốc độ theo dõi', N'750 IPS · gia tốc 50G'),
(1148, 1, N'Tần số quét', N'1000 Hz (8000 Hz với dongle rời)'),
(1149, 1, N'Trọng lượng', N'45 g'),
(1150, 1, N'Switch', N'Omron quang học (ATK tinh chỉnh)'),
(1151, 1, N'Dung lượng pin', N'250 mAh'),
(1152, 1, N'Thời lượng pin', N'~75 giờ ở 1000 Hz'),
(1153, 1, N'Kết nối', N'2.4 GHz không dây · USB-C có dây'),
(1154, 1, N'Kích thước', N'118,2 × 62,4 × 38,8 mm'),
(1155, 15, N'Cảm biến', N'PixArt PAW3950'),
(1156, 15, N'DPI tối đa', N'36.000 DPI'),
(1157, 15, N'Tốc độ theo dõi', N'750 IPS · gia tốc 70G'),
(1158, 15, N'Tần số quét', N'125 – 8000 Hz (8K cần dongle rời)'),
(1159, 15, N'Trọng lượng', N'50 g (±2 g)'),
(1160, 15, N'Switch', N'Omron quang học (ATK tinh chỉnh)'),
(1161, 15, N'Dung lượng pin', N'500 mAh'),
(1162, 15, N'Thời lượng pin', N'~150 giờ ở 1000 Hz'),
(1163, 15, N'Kết nối', N'2.4 GHz không dây · USB-C có dây'),
(1164, 15, N'Kích thước', N'118,2 × 62,4 × 38,8 mm'),
(1165, 16, N'Cảm biến', N'PixArt PAW3950 Ultra'),
(1166, 16, N'DPI tối đa', N'42.000 DPI (ép xung)'),
(1167, 16, N'Tốc độ theo dõi', N'750 IPS · gia tốc 50G'),
(1168, 16, N'Tần số quét', N'125 – 8000 Hz (cả có dây lẫn không dây)'),
(1169, 16, N'Trọng lượng', N'39 g'),
(1170, 16, N'Switch', N'ATK quang học tùy chỉnh'),
(1171, 16, N'Dung lượng pin', N'300 mAh'),
(1172, 16, N'Thời lượng pin', N'250+ giờ ở 1000 Hz'),
(1173, 16, N'Kết nối', N'2.4 GHz không dây · USB-C có dây'),
(1174, 16, N'Kích thước', N'118,2 × 62,4 × 38,8 mm'),
(1175, 14, N'Cảm biến', N'PixArt PAW3950 Ultra'),
(1176, 14, N'DPI tối đa', N'42.000 DPI (ép xung)'),
(1177, 14, N'Tốc độ theo dõi', N'750 IPS · gia tốc 50G'),
(1178, 14, N'Tần số quét', N'125 – 8000 Hz tích hợp sẵn, không cần dongle rời'),
(1179, 14, N'Trọng lượng', N'38 g'),
(1180, 14, N'Switch', N'Omron quang học'),
(1181, 14, N'Dung lượng pin', N'200 mAh (hỗ trợ sạc nhanh)'),
(1182, 14, N'Thời lượng pin', N'80+ giờ ở 1000 Hz'),
(1183, 14, N'Kết nối', N'2.4 GHz không dây · USB-C có dây'),
(1184, 14, N'Kích thước', N'118,2 × 62,4 × 38,8 mm'),
(1187, 2, N'Trọng lượng', N'49g'),
(1188, 2, N'Chip xử lý', N'Nordic 52840');
SET IDENTITY_INSERT [product_specs] OFF;
GO

-- product_variants (36 dong)
SET IDENTITY_INSERT [product_variants] ON;
INSERT INTO [product_variants] ([id], [product_id], [name], [color], [rgb_code], [image_url], [price], [stock], [is_active]) VALUES
(3, 1, N'F1 Ultimate', N'Trắng', N'#FFFFFF', N'1782277138021_ATK_Blazing_Sky_F1_White.png', 966000.00, 0, 0),
(4, 1, N'F1 Ultimate', N'Đen', N'#1a1a1a', N'1782621655778_atk_f1_ultimate.png', 966000.00, 0, 0),
(5, 2, N'X1 Pro', N'Đen', N'#000000', N'1784908308113_ATK_Blazing_Sky_X1_Black.webp', 1931000.00, 100, 1),
(6, 1, N'F1 Ultimate', N'Đỏ', N'#E53935', NULL, 966000.00, 0, 0),
(7, 1, N'F1 Pro', N'Đen', N'#000000', N'1785523295827_ATK_Blazing_Sky_F1_Black.webp', 966000.00, 10, 1),
(8, 1, N'F1 Pro', N'Trắng', N'#FFFFFF', N'1785523362782_ATK_Blazing_Sky_F1_White.webp', 966000.00, 10, 1),
(9, 1, N'F1 Pro Max', N'Đen', N'#000000', N'1785523432470_ATK_Blazing_Sky_F1_Black.webp', 966000.00, 0, 0),
(10, 1, N'F1 Pro Max', N'Trắng', N'#FFFFFF', N'1785523455409_ATK_Blazing_Sky_F1_White.webp', 966000.00, 0, 0),
(11, 1, N'F1 Extreme', N'Đen', N'#000000', N'1785523531095_ATK_Blazing_Sky_F1_Extreme_Black.webp', 966000.00, 0, 0),
(12, 1, N'F1 Extreme', N'Trắng', N'#FFFFFF', N'1785523592234_ATK_Blazing_Sky_F1_Extreme_White.webp', 966000.00, 0, 0),
(13, 1, N'F1 Ultra Max', N'Đen', N'#000000', N'1785523719764_1500_2b8821f6-daa0-4e48-a577-9edc72268bab.webp', 966000.00, 0, 0),
(14, 1, N'F1 Ultra Max', N'Trắng', N'#FFFFFF', N'1785523750955_1500_1aaebee8-b65f-4d5f-94b9-d43be42e54fd.webp', 966000.00, 0, 0),
(15, 1, N'F1 Ultimate', N'Tím nhạt', N'#C7CCEE', N'1785524011274_1500_3c8686bb-0248-4b4a-9787-486873cfeb35.webp', 966000.00, 0, 0),
(16, 1, N'F1 Ultimate', N'Hồng', N'#F0B7BF', N'1785524137731_1500_2bf9f01e-4331-4c66-9178-20ca5bf1e0fd.webp', 966000.00, 0, 0),
(17, 1, N'F1 Extreme 2.0', N'Xanh', N'#7DB2E8', N'1785524128021_1500_649110c8-f4d8-4f98-96d9-4327b7bc9a84.webp', 966000.00, 0, 0),
(18, 1, N'F1 Extreme 2.0', N'Hồng', N'#F0B7BF', N'1785524158370_1500_2bf9f01e-4331-4c66-9178-20ca5bf1e0fd.webp', 966000.00, 0, 0),
(19, 1, N'F1 Ultimate+', N'Đen', N'#000000', N'1785524216210_4fe40f089696834c4906303a743d01c5_e7aff1ff-9206-4ed5-80d5-7a2066ee6990.webp', 966000.00, 0, 0),
(20, 1, N'F1 Ultimate+', N'Trắng', N'#FFFFFF', N'1785524270220_33ffae0206d3c7cd1aadac09875e5e96_0b9f2910-f9b5-4227-acca-c9195f7efb06.webp', 966000.00, 0, 0),
(21, 1, N'F1 Ultimate+', N'Tím nhạt', N'#C6CBF0', N'1785524455070_1f271361c50a6f05a9257d8cfce56d69_ccfddbd0-d234-4879-addc-6c5920f2f283.webp', 966000.00, 0, 0),
(22, 1, N'F1 Ultimate+', N'Hồng', N'#F2A89D', N'1785524494586_ef4e53d14c6389f20f094f23aff2ad3c.webp', 966000.00, 0, 0),
(23, 1, N'F1 Extreme+', N'Hồng', N'#000000', N'1785524523889_ef4e53d14c6389f20f094f23aff2ad3c.webp', 966000.00, 0, 0),
(24, 1, N'F1 Ultimate+', N'Xanh Bạc Hà', N'#9FE2C6', N'1785524562064_95897aaf923d03f4229c01af61ebc8e0_a8f3b4aa-6d3f-48b1-be46-58c08ab2f682.webp', 966000.00, 0, 0),
(25, 1, N'F1 Ultimate+', N'Xanh', N'#72ACE9', N'1785524587024_95897aaf923d03f4229c01af61ebc8e0_a8f3b4aa-6d3f-48b1-be46-58c08ab2f682.webp', 966000.00, 0, 0),
(26, 1, N'F1 Extreme+', N'Xanh', N'#72ACE9', N'1785524610829_95897aaf923d03f4229c01af61ebc8e0_a8f3b4aa-6d3f-48b1-be46-58c08ab2f682.webp', 966000.00, 0, 0),
(27, 12, N'F1 Ultra Max 2.0', N'Đen', N'#000000', N'1785563622988_1500_2b8821f6-daa0-4e48-a577-9edc72268bab.webp', 1086000.00, 0, 1),
(28, 12, N'F1 Ultra Max 2.0', N'Trắng', N'#FFFFFF', N'1785563674533_1500_1aaebee8-b65f-4d5f-94b9-d43be42e54fd.webp', 1086000.00, 0, 1),
(29, 13, N'F1 Ultimate 2.0', N'Đen', N'#000000', N'1785564130631_1500_2b8821f6-daa0-4e48-a577-9edc72268bab_(1).webp', 1449000.00, 0, 1),
(30, 13, N'F1 Ultimate 2.0', N'Trắng', N'#FFFFFF', N'1785564170580_1500_1aaebee8-b65f-4d5f-94b9-d43be42e54fd.webp', 1449000.00, 0, 1),
(31, 13, N'F1 Ultimate 2.0', N'Hồng', N'#F0B7BF', N'1785564222430_1500_2bf9f01e-4331-4c66-9178-20ca5bf1e0fd.webp', 1449000.00, 0, 1),
(32, 13, N'F1 Ultimate 2.0', N'Tím nhạt', N'#C7CCEE', N'1785564264854_1500_3c8686bb-0248-4b4a-9787-486873cfeb35.webp', 1449000.00, 0, 1),
(33, 14, NULL, N'Đen', N'#000000', N'1785523531095_ATK_Blazing_Sky_F1_Extreme_Black.webp', 1449000.00, 10, 1),
(34, 14, NULL, N'Trắng', N'#FFFFFF', N'1785523592234_ATK_Blazing_Sky_F1_Extreme_White.webp', 1449000.00, 10, 1),
(35, 15, NULL, N'Đen', N'#000000', N'1785523432470_ATK_Blazing_Sky_F1_Black.webp', 1207000.00, 10, 1),
(36, 15, NULL, N'Trắng', N'#FFFFFF', N'1785523455409_ATK_Blazing_Sky_F1_White.webp', 1207000.00, 10, 1),
(37, 16, NULL, N'Trắng', N'#FFFFFF', N'1782277138021_ATK_Blazing_Sky_F1_White.png', 1450000.00, 24, 1),
(38, 16, NULL, N'Đen', N'#1a1a1a', N'1782621655778_atk_f1_ultimate.png', 1450000.00, 23, 1);
SET IDENTITY_INSERT [product_variants] OFF;
GO

-- products (16 dong)
SET IDENTITY_INSERT [products] ON;
INSERT INTO [products] ([id], [category_id], [name], [description], [price], [stock_quantity], [image_url], [is_active], [created_at], [updated_at], [switch_type], [weight_group], [connectivity], [warranty_months], [line_id]) VALUES
(1, 1, N'Chuột ATK F1 Pro', N'Chuột siêu nhẹ 38g, Mắt đọc PAW3395, Polling Rate 8000Hz không dây.', 966000.00, 20, N'atk_f1_ultimate.png', 1, NULL, N'2026-08-01 13:11:27.6866563', NULL, N'ULTRA', N'DUAL', 12, 1),
(2, 1, N'Chuột ATK X1 Pro Max', N'Form chuột công thái học, nặng 49g, chip Nordic 52840 cao cấp.', 790000.00, 100, N'atk_x1_promax.png', 1, N'2026-06-02 21:22:20.38', N'2026-08-02 01:48:13.7938703', NULL, N'ULTRA', N'DUAL', NULL, 3),
(3, 2, N'Bàn phím Từ Tính ATK68 v2', N'Bàn phím cơ Hall Effect chuyên Game FPS, Rapid Trigger siêu nhạy.', 2100000.00, 10, N'atk68_v2.png', 1, N'2026-06-02 21:22:20.38', N'2026-06-02 21:22:20.38', N'MAGNETIC', NULL, N'WIRED', NULL, NULL),
(4, 2, N'Bàn phím Cơ ATK V75 Pro', N'Layout 75%, Gasket mount, Switch mượt mà có sẵn đệm tiêu âm.', 1850000.00, 0, N'atk_v75_pro.png', 1, N'2026-06-02 21:22:20.38', N'2026-06-11 11:37:17.9157207', N'LINEAR', NULL, N'DUAL', NULL, NULL),
(5, 3, N'Tai nghe ATK Mercury I Wireless', N'Tai nghe eSports không dây Tri-mode, kết nối 2.4G / Bluetooth / Dây Type-C, độ trễ cực thấp.', 950000.00, 20, N'atk_mercury.png', 1, NULL, N'2026-06-09 21:15:53.1185429', NULL, NULL, N'WIRELESS', NULL, NULL),
(6, 2, N'Bàn phím ATK RS6 Air', N'Bàn phím cơ Hall Effect 65%, kết nối không dây, Rapid Trigger siêu nhạy.', 2500000.00, 0, N'atk_rs6_air.png', 0, N'2026-06-11 09:37:30.2381519', N'2026-06-11 09:37:30.2381519', N'TACTILE', NULL, N'WIRED', NULL, NULL),
(7, 3, N'Tai nghe ATK Neptune N9 Wireless', N'Tai nghe gaming không dây eSports, kết nối 2.4G / Bluetooth / Dây Type-C, âm thanh surround 7.1.', 1200000.00, 0, N'atk_neptune_n9.png', 1, N'2026-06-12 18:53:38.2504892', N'2026-06-12 18:53:38.2504892', NULL, NULL, N'WIRELESS', NULL, NULL),
(8, 3, N'Tai nghe ATK Horizon DSP In-ear', N'Tai nghe in-ear gaming, DSP chip xử lý âm thanh, kết nối có dây 3.5mm / Type-C.', 650000.00, 0, N'atk_horizon_dsp.png', 1, N'2026-06-12 18:56:05.1378943', N'2026-06-12 18:56:05.1378943', NULL, NULL, N'WIRED', NULL, NULL),
(9, 1, N'Chuột ATK Dragonfly A9 Wireless', N'Chuột gaming siêu nhẹ không dây, thiết kế tối ưu cho eSports, kết nối 2.4G / Bluetooth.', 1650000.00, 20, N'atk_dragonfly_a9.png', 1, N'2026-06-12 18:58:37.354337', N'2026-08-01 12:44:02.4982528', NULL, N'ULTRA', N'WIRELESS', NULL, 2),
(10, 2, N'Bàn phím ATK RS6+ Aluminum Magnetic', N'Bàn phím cơ vỏ nhôm nguyên khối, Magnetic Switch từ tính, Rapid Trigger siêu nhạy, layout 65%.', 2800000.00, 0, N'atk_rs6_plus.png', 1, N'2026-06-12 19:03:56.1216414', N'2026-06-12 19:03:56.1216414', N'TACTILE', NULL, N'WIRED', NULL, NULL),
(11, 1, N'Chuột ATK F1 Ultimate11222', N'1111', 20000.00, 10, N'1781656903277_Screenshot_2026-06-17_073907.png', 1, N'2026-06-16 09:33:17.5957192', N'2026-06-17 07:41:43.286739', NULL, N'ULTRA', N'WIRELESS', NULL, NULL),
(12, 1, N'Chuột ATK F1 Ultra Max 2.0', N'Được trang bị dòng vi điều khiển (MCU) Nordic 54 cao cấp trên tất cả các phiên bản, kết hợp cùng lớp phủ nano hoàn toàn mới và đa dạng tùy chọn màu sắc phù hợp với nhiều phong cách, mang lại trải nghiệm thực sự mới mẻ.', 1086000.00, 0, N'1785563635530_1500_2b8821f6-daa0-4e48-a577-9edc72268bab.webp', 1, N'2026-08-01 02:13:13.9573384', N'2026-08-01 12:53:55.5587766', NULL, N'ULTRA', N'DUAL', 12, 4),
(13, 1, N'Chuột ATK F1 Ultimate 2.0', N'Được trang bị dòng vi điều khiển (MCU) Nordic 54 cao cấp trên tất cả các phiên bản, kết hợp cùng lớp phủ nano hoàn toàn mới và đa dạng tùy chọn màu sắc phù hợp với nhiều phong cách, mang lại trải nghiệm thực sự mới mẻ.', 1449000.00, 0, N'1785564050146_1500_2b8821f6-daa0-4e48-a577-9edc72268bab_(1).webp', 1, N'2026-08-01 13:00:50.1774249', N'2026-08-01 13:00:50.1774249', N'', N'ULTRA', N'', 12, 4),
(14, 1, N'Chuột ATK F1 Extreme', N'Chuột siêu nhẹ 38g, Mắt đọc PAW3395, Polling Rate 8000Hz không dây.', 1449000.00, 20, N'1785523592234_ATK_Blazing_Sky_F1_Extreme_White.webp', 1, N'2026-08-01 13:24:15.1933333', N'2026-08-01 13:24:15.1933333', NULL, N'ULTRA', N'DUAL', 12, 1),
(15, 1, N'Chuột ATK F1 Pro Max', N'Chuột siêu nhẹ 38g, Mắt đọc PAW3395, Polling Rate 8000Hz không dây.', 1207000.00, 20, N'1785523455409_ATK_Blazing_Sky_F1_White.webp', 1, N'2026-08-01 13:24:15.1933333', N'2026-08-01 13:24:15.1933333', NULL, N'ULTRA', N'DUAL', 12, 1),
(16, 1, N'Chuột ATK F1 Ultimate', N'Chuột siêu nhẹ 38g, Mắt đọc PAW3395, Polling Rate 8000Hz không dây.', 1450000.00, 47, N'1782621655778_atk_f1_ultimate.png', 1, N'2026-08-01 13:24:15.1933333', N'2026-08-01 13:24:15.1933333', NULL, N'ULTRA', N'DUAL', 12, 1);
SET IDENTITY_INSERT [products] OFF;
GO

-- restock_notifications (2 dong)
SET IDENTITY_INSERT [restock_notifications] ON;
INSERT INTO [restock_notifications] ([id], [product_id], [email], [is_notified], [created_at], [variant_id]) VALUES
(1, 9, N'minhtuz5709@gmail.com', 1, N'2026-07-25 21:34:16.0910318', NULL),
(2, 3, N'minhtuz5709@gmail.com', 1, N'2026-07-27 10:01:58.9865863', NULL);
SET IDENTITY_INSERT [restock_notifications] OFF;
GO

-- reviews (2 dong)
SET IDENTITY_INSERT [reviews] ON;
INSERT INTO [reviews] ([id], [product_id], [user_id], [rating], [comment], [created_at], [updated_at]) VALUES
(1, 1, 3, 5, N'lỏ', N'2026-07-15 10:10:38.1441807', N'2026-07-15 10:10:38.1441807'),
(2, 1, 1, 1, N'gsfdgf', N'2026-07-27 10:01:00.978207', N'2026-07-27 10:01:18.0699116');
SET IDENTITY_INSERT [reviews] OFF;
GO

-- stock_in (13 dong)
SET IDENTITY_INSERT [stock_in] ON;
INSERT INTO [stock_in] ([id], [product_id], [quantity], [import_price], [supplier], [note], [imported_by], [imported_at], [remaining_quantity], [received_at], [checked_at], [variant_id], [khu], [ke]) VALUES
(1012, 16, 25, 1100000.00, N'', N'', 1, N'2026-07-24 19:39:41.717194', 23, NULL, NULL, 38, N'A', 9),
(1013, 16, 25, 1100000.00, N'', N'', 1, N'2026-07-24 19:46:22.3097624', 24, NULL, NULL, 37, N'A', 9),
(1014, 2, 100, 800000.00, N'', N'', 1, N'2026-07-24 22:48:14.8256739', 100, NULL, NULL, 5, N'A', 2),
(1015, 9, 20, 1300000.00, N'', N'', 1, N'2026-07-25 21:40:54.490476', 20, NULL, NULL, NULL, N'A', 3),
(1016, 3, 10, 11.00, N'ATK', N'', 1, N'2026-07-27 10:03:42.9109138', 10, NULL, NULL, NULL, N'C', 1),
(1017, 1, 10, 1000000.00, N'ATK', N'', 1, N'2026-08-01 02:05:08.4443807', 10, NULL, NULL, 7, N'A', 1),
(1018, 1, 10, 1000000.00, N'ATK', N'a', 1, N'2026-08-01 02:05:26.5930186', 10, NULL, NULL, 8, N'A', 1),
(1019, 15, 10, 1000000.00, N'ATK', N'', 1, N'2026-08-01 02:05:54.345398', 10, NULL, NULL, 35, N'A', 8),
(1020, 15, 10, 1000000.00, N'', N'', 1, N'2026-08-01 02:06:10.4261359', 10, NULL, NULL, 36, N'A', 8),
(1021, 14, 10, 1000000.00, N'ATK', N'', 1, N'2026-08-01 02:08:36.0313269', 10, NULL, NULL, 33, N'A', 7),
(1022, 14, 10, 1000000.00, N'ATK', N'', 1, N'2026-08-01 02:08:47.2635599', 10, NULL, NULL, 34, N'A', 7),
(1023, 5, 20, 900000.00, N'ATK', N'', 1, N'2026-08-01 12:46:55.0220765', 20, NULL, NULL, NULL, N'B', 1),
(1024, 11, 10, 1.00, N'1', N'', 1, N'2026-08-01 23:51:19.3919923', 10, NULL, NULL, NULL, N'A', 4);
SET IDENTITY_INSERT [stock_in] OFF;
GO

-- stock_out (4 dong)
SET IDENTITY_INSERT [stock_out] ON;
INSERT INTO [stock_out] ([id], [exported_by], [exported_at], [note], [import_cost], [order_item_id], [stock_in_id], [quantity], [is_returned], [returned_at]) VALUES
(1018, 1, N'2026-07-24 20:33:05.7377457', N'FIFO 1 san pham tu lo nhap #1012 gia 1100000.00d', 1100000.00, 1034, 1012, 1, 1, N'2026-07-26 17:28:16.4816176'),
(1019, 1, N'2026-07-29 21:45:33.6754556', N'FIFO 2 san pham tu lo nhap #1012 gia 1100000.00d', 1100000.00, 1039, 1012, 2, 0, NULL),
(1020, 1, N'2026-08-01 02:23:47.1554655', N'FIFO 1 san pham tu lo nhap #1013 gia 1100000.00d', 1100000.00, 1041, 1013, 1, 0, NULL),
(1021, 1, N'2026-08-01 20:26:42.2733723', N'FIFO 1 san pham tu lo nhap #1014 gia 800000.00d', 800000.00, 1040, 1014, 1, 1, N'2026-08-01 20:27:10.455113');
SET IDENTITY_INSERT [stock_out] OFF;
GO

-- system_settings (12 dong)
SET IDENTITY_INSERT [system_settings] ON;
INSERT INTO [system_settings] ([id], [setting_key], [setting_value], [description]) VALUES
(1, N'MAX_QTY_PER_PRODUCT_PER_ORDER', N'10', N'Số lượng tối đa của 1 sản phẩm được mua trong 1 đơn hàng, nhằm tránh mua sỉ qua web bán lẻ'),
(3, N'COD_MAX_QTY_PER_PRODUCT', N'3', N'Số lượng tối đa của 1 sản phẩm được phép chọn COD — vượt quá số này, khách bắt buộc phải thanh toán trước qua chuyển khoản (VNPAY) mới đặt được đơn'),
(4, N'COD_MAX_ORDER_AMOUNT', N'4000000', N'Đơn hàng có tổng giá trị vượt quá số tiền này (VNĐ) bắt buộc phải thanh toán trước qua chuyển khoản (VNPAY), không quan tâm số lượng sản phẩm'),
(5, N'WAREHOUSE_CAN_VIEW_PRODUCTS', N'true', N'Cho phép tài khoản Thủ Kho xem danh sách sản phẩm (chỉ xem, không thêm/sửa/xóa được)'),
(6, N'WAREHOUSE_CAN_VIEW_REVENUE', N'false', N'Cho phép tài khoản Thủ Kho xem báo cáo doanh thu'),
(7, N'WAREHOUSE_CAN_MANAGE_ORDERS', N'false', N'Cho phép tài khoản Thủ Kho xem và cập nhật trạng thái đơn hàng (duyệt xuất kho, đánh dấu hoàn thành...)'),
(8, N'COD_MAX_ACTIVE_ORDERS', N'3', N'Số đơn COD (thanh toán khi nhận hàng) tối đa mà 1 khách được có cùng lúc khi chưa giao xong — chống bom hàng mà không cấm mua lại. Đơn đã thanh toán trước qua chuyển khoản (VNPAY) KHÔNG bị giới hạn'),
(9, N'SHOP_ADDRESS', N'42 Nguyễn Văn Tiết, Thủ Dầu Một, TP. Hồ Chí Minh', N'Địa chỉ cửa hàng — hiện ở chân trang và trang tra cứu bảo hành (chỗ khách mang máy tới).'),
(10, N'SHOP_PROVINCE', N'TP. Hồ Chí Minh', N'Tỉnh/thành đặt kho. Đơn giao trong tỉnh này tính phí nội tỉnh, ngoài tỉnh tính phí liên tỉnh. PHẢI khớp với tỉnh trong SHOP_ADDRESS.'),
(11, N'SHIPPING_FEE_SAME_PROVINCE', N'20000', N'Phí vận chuyển khi giao trong cùng tỉnh với kho (đồng).'),
(12, N'SHIPPING_FEE_OTHER_PROVINCE', N'35000', N'Phí vận chuyển khi giao sang tỉnh khác (đồng).'),
(13, N'FREE_SHIPPING_THRESHOLD', N'500000', N'Đơn có tiền hàng từ mức này trở lên được miễn phí vận chuyển (đồng). Đặt 0 để không bao giờ miễn phí.');
SET IDENTITY_INSERT [system_settings] OFF;
GO

-- users (6 dong)
SET IDENTITY_INSERT [users] ON;
INSERT INTO [users] ([id], [full_name], [email], [phone], [password_hash], [role], [address], [created_at], [is_active]) VALUES
(1, N'Nguyễn Văn Admin', N'admin@titanstore.com', N'0912345678', N'$2b$10$0dbC2LImpAxNmAMMhMcMxecqiqhx1JR42VT7JYRUP6KOdg2/QFmMC', N'ADMIN', N'42 Nguyen Van Tiet, TP.HCM', N'2026-06-02 21:22:20.3766667', 1),
(2, N'Thủ Kho', N'warehouse@titanstore.com', N'0987654321', N'$2b$10$0NNJWbZqHwvRLWf32sM0ae6tds21v/BkYIA.94mMEuxgJb7D8Itg2', N'WAREHOUSE', N'Kho tổng TITAN, TP. HCM', N'2026-06-02 21:22:20.3766667', 1),
(3, N'A du anh Hai', N'khachhang1@gmail.com', N'0905111222', N'$2b$10$g2x4YhRXd8aYzEhYitOPkOTGCSk8hInIX9EMI4IyndGiCoehkIwuS', N'CUSTOMER', N'123 Phu Hoa, TP.HCM', N'2026-06-02 21:22:20.3766667', 1),
(4, N'Phạm Hải Nam', N'namph@gmail.com', N'0934555666', N'$2b$10$ThW1ti0R0Y5vGy2LDFlHTOzmDpVf914dvrBsJLbv1eIH.Q3Olcua2', N'CUSTOMER', N'456 Lê Lợi, Quận 1, TP. HCM', N'2026-06-02 21:22:20.3766667', 1),
(5, N'Phạm Minh Tú', N'tupmtv00386@gmail.com', N'0335997359', N'$2b$10$r2Y3LWuHiJyfB/mJFXksG.NhSv3T4wUGG93Q6xt0h25.UvOMNZOsy', N'CUSTOMER', NULL, N'2026-06-16 09:08:56.1892219', 1),
(6, N'Phạm Minh Tú', N'minhtuz5709@gmail.com', N'0335997359', N'$2a$10$Dxm4Kla0LC7kSyV5wKifPeJQZfGOQW1WV9a3cBORyqzhNu0v736Y2', N'CUSTOMER', NULL, N'2026-07-24 00:02:44.2367827', 1);
SET IDENTITY_INSERT [users] OFF;
GO

-- voucher_usages (2 dong)
SET IDENTITY_INSERT [voucher_usages] ON;
INSERT INTO [voucher_usages] ([id], [voucher_id], [user_id], [order_id], [discount_amount], [used_at]) VALUES
(1, 1, 1, 1032, 100000.00, N'2026-07-26 20:40:19.087979'),
(2, 2, 1, 1035, 420000.00, N'2026-07-27 10:04:30.5727367');
SET IDENTITY_INSERT [voucher_usages] OFF;
GO

-- vouchers (4 dong)
SET IDENTITY_INSERT [vouchers] ON;
INSERT INTO [vouchers] ([id], [code], [description], [discount_type], [discount_value], [min_order_amount], [max_discount_amount], [start_at], [end_at], [usage_limit], [used_count], [once_per_user], [is_active], [created_at], [combo_id], [chi_don_co_combo]) VALUES
(1, N'GIAM10', N'Giảm 10% cho đơn từ 500k', N'PERCENT', 10.00, 500000.00, 100000.00, NULL, NULL, 100, 1, 1, 1, N'2026-07-26 20:38:25.9201576', NULL, 0),
(2, N'GIAM20', N'Giảm 20% cho đơn từ 500k', N'PERCENT', 20.00, 500000.00, 1000000.00, NULL, NULL, 10, 1, 1, 1, N'2026-07-27 09:55:09.2501082', NULL, 0),
(3, N'COMBOSILENT', N'Giam 100k rieng cho Combo Silent Work', N'AMOUNT', 100000.00, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, N'2026-08-01 19:31:53.2717804', 2, 0),
(4, N'TTGLFPPYR', N'323', N'PERCENT', 10.00, 10000.00, 500000.00, NULL, NULL, NULL, 0, 1, 1, N'2026-08-03 10:33:01.3605897', NULL, 0);
SET IDENTITY_INSERT [vouchers] OFF;
GO

-- warranties (3 dong)
SET IDENTITY_INSERT [warranties] ON;
INSERT INTO [warranties] ([id], [serial_no], [order_item_id], [product_id], [user_id], [start_date], [end_date], [note], [created_at]) VALUES
(1, N'SR000001', 1039, 1, 1, N'2026-07-29', N'2026-08-08', NULL, N'2026-07-29 21:45:35.4623864'),
(2, N'SR000002', 1039, 1, 1, N'2026-07-29', N'2026-07-24', NULL, N'2026-07-29 21:45:35.4792441'),
(3, N'SR000003', 1041, 1, 1, N'2026-08-01', N'2027-08-01', NULL, N'2026-08-01 10:30:35.148904');
SET IDENTITY_INSERT [warranties] OFF;
GO

-- warranty_repairs (2 dong)
SET IDENTITY_INSERT [warranty_repairs] ON;
INSERT INTO [warranty_repairs] ([id], [warranty_id], [noi_dung], [trang_thai], [created_at]) VALUES
(1, 2, N'Khách báo lỗi nút chuột trái', N'TIEP_NHAN', N'2026-07-29 21:46:31.6203866'),
(2, 1, N'Khách mang máy tới kiểm tra double-click', N'DANG_SUA', N'2026-07-30 09:34:24.6566229');
SET IDENTITY_INSERT [warranty_repairs] OFF;
GO

/* ---------- 3. Khoa ngoai ---------- */
ALTER TABLE [product_variants] ADD CONSTRAINT [FK__product_v__produ__17F790F9]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]);
ALTER TABLE [audit_log] ADD CONSTRAINT [FK_AuditLog_Users]
    FOREIGN KEY ([user_id]) REFERENCES [users] ([id]);
ALTER TABLE [cart_items] ADD CONSTRAINT [FK_Cart_Products]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]) ON DELETE CASCADE;
ALTER TABLE [cart_items] ADD CONSTRAINT [FK_Cart_Users]
    FOREIGN KEY ([user_id]) REFERENCES [users] ([id]);
ALTER TABLE [cart_items] ADD CONSTRAINT [FK_Cart_Variants]
    FOREIGN KEY ([variant_id]) REFERENCES [product_variants] ([id]) ON DELETE SET NULL;
ALTER TABLE [cart_items] ADD CONSTRAINT [FK_CartItems_ComboItems]
    FOREIGN KEY ([combo_item_id]) REFERENCES [combo_items] ([id]);
ALTER TABLE [cart_items] ADD CONSTRAINT [FK_CartItems_Combos]
    FOREIGN KEY ([combo_id]) REFERENCES [combos] ([id]);
ALTER TABLE [combo_items] ADD CONSTRAINT [FK_ComboItems_Combos]
    FOREIGN KEY ([combo_id]) REFERENCES [combos] ([id]);
ALTER TABLE [combo_items] ADD CONSTRAINT [FK_ComboItems_Products]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]);
ALTER TABLE [combo_items] ADD CONSTRAINT [FK_ComboItems_Variants]
    FOREIGN KEY ([variant_id]) REFERENCES [product_variants] ([id]);
ALTER TABLE [stock_out] ADD CONSTRAINT [FK_Exports_OrderItems]
    FOREIGN KEY ([order_item_id]) REFERENCES [order_items] ([id]);
ALTER TABLE [stock_out] ADD CONSTRAINT [FK_Exports_StockImports]
    FOREIGN KEY ([stock_in_id]) REFERENCES [stock_in] ([id]);
ALTER TABLE [stock_out] ADD CONSTRAINT [FK_Exports_Users]
    FOREIGN KEY ([exported_by]) REFERENCES [users] ([id]);
ALTER TABLE [flash_sale_items] ADD CONSTRAINT [FK_FlashSaleItems_FlashSales]
    FOREIGN KEY ([flash_sale_id]) REFERENCES [flash_sales] ([id]) ON DELETE CASCADE;
ALTER TABLE [flash_sale_items] ADD CONSTRAINT [FK_FlashSaleItems_Products]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]);
ALTER TABLE [flash_sales] ADD CONSTRAINT [FK_FlashSales_Users]
    FOREIGN KEY ([created_by]) REFERENCES [users] ([id]);
ALTER TABLE [stock_in] ADD CONSTRAINT [FK_Imports_Products]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]);
ALTER TABLE [stock_in] ADD CONSTRAINT [FK_Imports_Users]
    FOREIGN KEY ([imported_by]) REFERENCES [users] ([id]);
ALTER TABLE [order_items] ADD CONSTRAINT [FK_OrderItems_Combos]
    FOREIGN KEY ([combo_id]) REFERENCES [combos] ([id]);
ALTER TABLE [order_items] ADD CONSTRAINT [FK_OrderItems_Orders]
    FOREIGN KEY ([order_id]) REFERENCES [orders] ([id]) ON DELETE CASCADE;
ALTER TABLE [order_items] ADD CONSTRAINT [FK_OrderItems_Products]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]);
ALTER TABLE [order_items] ADD CONSTRAINT [FK_OrderItems_Variants]
    FOREIGN KEY ([variant_id]) REFERENCES [product_variants] ([id]);
ALTER TABLE [orders] ADD CONSTRAINT [FK_Orders_Users]
    FOREIGN KEY ([user_id]) REFERENCES [users] ([id]);
ALTER TABLE [orders] ADD CONSTRAINT [FK_Orders_Voucher]
    FOREIGN KEY ([voucher_id]) REFERENCES [vouchers] ([id]);
ALTER TABLE [products] ADD CONSTRAINT [FK_Product_Line]
    FOREIGN KEY ([line_id]) REFERENCES [product_lines] ([id]);
ALTER TABLE [products] ADD CONSTRAINT [FK_Products_Categories]
    FOREIGN KEY ([category_id]) REFERENCES [categories] ([id]);
ALTER TABLE [warranty_repairs] ADD CONSTRAINT [FK_Rep_Warranty]
    FOREIGN KEY ([warranty_id]) REFERENCES [warranties] ([id]);
ALTER TABLE [restock_notifications] ADD CONSTRAINT [FK_Restock_Products]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]);
ALTER TABLE [restock_notifications] ADD CONSTRAINT [FK_Restock_Variants]
    FOREIGN KEY ([variant_id]) REFERENCES [product_variants] ([id]);
ALTER TABLE [reviews] ADD CONSTRAINT [FK_Reviews_Products]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]);
ALTER TABLE [reviews] ADD CONSTRAINT [FK_Reviews_Users]
    FOREIGN KEY ([user_id]) REFERENCES [users] ([id]);
ALTER TABLE [product_specs] ADD CONSTRAINT [FK_Specs_Products]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]) ON DELETE CASCADE;
ALTER TABLE [stock_in] ADD CONSTRAINT [FK_StockIn_Variants]
    FOREIGN KEY ([variant_id]) REFERENCES [product_variants] ([id]);
ALTER TABLE [vouchers] ADD CONSTRAINT [FK_Vouchers_Combos]
    FOREIGN KEY ([combo_id]) REFERENCES [combos] ([id]);
ALTER TABLE [voucher_usages] ADD CONSTRAINT [FK_VU_Order]
    FOREIGN KEY ([order_id]) REFERENCES [orders] ([id]);
ALTER TABLE [voucher_usages] ADD CONSTRAINT [FK_VU_User]
    FOREIGN KEY ([user_id]) REFERENCES [users] ([id]);
ALTER TABLE [voucher_usages] ADD CONSTRAINT [FK_VU_Voucher]
    FOREIGN KEY ([voucher_id]) REFERENCES [vouchers] ([id]);
ALTER TABLE [warranties] ADD CONSTRAINT [FK_War_OrderItem]
    FOREIGN KEY ([order_item_id]) REFERENCES [order_items] ([id]);
ALTER TABLE [warranties] ADD CONSTRAINT [FK_War_Product]
    FOREIGN KEY ([product_id]) REFERENCES [products] ([id]);
ALTER TABLE [warranties] ADD CONSTRAINT [FK_War_User]
    FOREIGN KEY ([user_id]) REFERENCES [users] ([id]);
GO

/* ---------- 4. Chi muc (toc do truy van) ---------- */
CREATE INDEX [IX_AuditLog_DoiTuong] ON [audit_log] ([doi_tuong], [doi_tuong_id], [thoi_diem] DESC);
CREATE INDEX [IX_AuditLog_ThoiDiem] ON [audit_log] ([thoi_diem] DESC);
CREATE INDEX [IX_CartItems_Combo] ON [cart_items] ([user_id], [combo_id]);
CREATE INDEX [IX_FlashSaleItems_Product] ON [flash_sale_items] ([product_id]);
CREATE INDEX [IX_FlashSales_ActiveLookup] ON [flash_sales] ([display_type], [is_active], [start_at], [end_at]);
CREATE INDEX [IX_imports_fifo] ON [stock_in] ([product_id], [imported_at]);
CREATE INDEX [IX_OrderItems_Combo] ON [order_items] ([combo_id]);
CREATE INDEX [IX_OrderItems_Product] ON [order_items] ([product_id]);
CREATE INDEX [IX_Orders_Payment_Status] ON [orders] ([payment_method], [status], [created_at]);
CREATE INDEX [IX_Orders_Status_Created] ON [orders] ([status], [created_at] DESC);
CREATE INDEX [IX_Orders_User_Created] ON [orders] ([user_id], [created_at] DESC);
CREATE INDEX [IX_Products_Active_Created] ON [products] ([is_active], [created_at] DESC);
CREATE INDEX [IX_Products_Category_Active] ON [products] ([category_id], [is_active]) INCLUDE ([name], [price], [stock_quantity], [image_url]);
CREATE INDEX [IX_Products_Line] ON [products] ([line_id], [is_active]);
CREATE INDEX [IX_Reviews_Product] ON [reviews] ([product_id], [created_at] DESC);
CREATE INDEX [IX_Specs_Product] ON [product_specs] ([product_id]);
CREATE INDEX [IX_StockIn_FIFO] ON [stock_in] ([product_id], [variant_id], [imported_at]);
CREATE INDEX [IX_Variants_Product] ON [product_variants] ([product_id], [is_active]);
CREATE INDEX [IX_VoucherUsages_VoucherUser] ON [voucher_usages] ([voucher_id], [user_id]);
CREATE INDEX [IX_Warranties_Serial] ON [warranties] ([serial_no]);
CREATE INDEX [IX_Warranties_User] ON [warranties] ([user_id]);
GO

/* ---------- 5. Trigger, View, Thu tuc ---------- */
/* Tao SAU CUNG. Trigger la thu giu cho cot ton kho luon dung:
   products.stock_quantity va product_variants.stock KHONG do Java ghi,
   ma do trigger tu cong/tru moi khi co dong nhap kho hoac xuat kho. */

-- TRIGGER: TRG_OrderItems_MaxQtyLimit
CREATE TRIGGER TRG_OrderItems_MaxQtyLimit
ON order_items
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @maxQty INT;
    SELECT @maxQty = TRY_CAST(setting_value AS INT)
    FROM system_settings
    WHERE setting_key = N'MAX_QTY_PER_PRODUCT_PER_ORDER';

    IF @maxQty IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE quantity > @maxQty)
    BEGIN
        RAISERROR(N'Số lượng mua vượt quá giới hạn cho phép mỗi đơn hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
GO

-- TRIGGER: TRG_StockIn_SyncProductStock
-- ---------------------------------------------------------------------
-- PHẦN 2: TRIGGER — đồng bộ tồn cho CẢ products VÀ product_variants
--   (giữ nguyên logic products cũ, THÊM nhánh product_variants)
-- ---------------------------------------------------------------------
CREATE   TRIGGER TRG_StockIn_SyncProductStock
ON stock_in
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- (giữ nguyên) tồn SẢN PHẨM = SUM remaining_quantity của MỌI lô của SP đó
    UPDATE p
    SET p.stock_quantity = ISNULL((
        SELECT SUM(si.remaining_quantity)
        FROM stock_in si
        WHERE si.product_id = p.id
    ), 0)
    FROM products p
    WHERE p.id IN (
        SELECT product_id FROM inserted
        UNION
        SELECT product_id FROM deleted
    );

    -- (MỚI) tồn BIẾN THỂ = SUM remaining_quantity của các lô thuộc biến thể đó
    UPDATE v
    SET v.stock = ISNULL((
        SELECT SUM(si.remaining_quantity)
        FROM stock_in si
        WHERE si.variant_id = v.id
    ), 0)
    FROM product_variants v
    WHERE v.id IN (
        SELECT variant_id FROM inserted WHERE variant_id IS NOT NULL
        UNION
        SELECT variant_id FROM deleted  WHERE variant_id IS NOT NULL
    );
END
GO

-- TRIGGER: TRG_StockOut_ApplyToStockIn
-- ------------------------------------------------------------
-- Trigger 2: khi có dòng stock_out mới, trừ đúng lô stock_in tương ứng
-- ------------------------------------------------------------
CREATE TRIGGER TRG_StockOut_ApplyToStockIn
ON stock_out
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Trừ số lượng xuất khỏi đúng lô nhập tương ứng
    UPDATE si
    SET si.remaining_quantity = si.remaining_quantity - i.quantity
    FROM stock_in si
    JOIN inserted i ON i.stock_in_id = si.id;
END
GO


PRINT N'== TITANGEAR_DB da san sang ==';
GO
