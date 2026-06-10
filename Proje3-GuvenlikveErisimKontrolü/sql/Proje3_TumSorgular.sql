/* ============================================================
   BLM4522 - PROJE 3: VERİTABANI GÜVENLİĞİ VE ERİŞİM KONTROLÜ
   Veritabanı: BikeStores  |  Platform: MS SQL Server (LocalDB)
   Ezgi SANKIR - 21290431
   ============================================================ */

/* ------------------------------------------------------------
   2. VERİTABANI TANITIMI
   ------------------------------------------------------------ */
USE BikeStores;

-- 2.1 Tablo Yapısı
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- 2.2 Kayıt Sayıları
SELECT 'customers' AS Tablo, COUNT(*) AS KayitSayisi FROM sales.customers UNION ALL
SELECT 'orders', COUNT(*) FROM sales.orders UNION ALL
SELECT 'order_items', COUNT(*) FROM sales.order_items UNION ALL
SELECT 'products', COUNT(*) FROM production.products UNION ALL
SELECT 'staffs', COUNT(*) FROM sales.staffs UNION ALL
SELECT 'stores', COUNT(*) FROM sales.stores
ORDER BY KayitSayisi DESC;

-- 2.3 Sütun Yapısı
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('customers','staffs')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- 2.4 Örnek Veri
SELECT TOP 10 customer_id, first_name, last_name, phone, email, city, state
FROM sales.customers;


/* ------------------------------------------------------------
   3. ERİŞİM YÖNETİMİ
   ------------------------------------------------------------ */
-- 3.1 Mevcut Kullanıcı ve Roller
SELECT dp.name AS KullaniciAdi, dp.type_desc AS Tur, rp.name AS RolAdi
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals rp ON drm.role_principal_id = rp.principal_id
WHERE dp.type NOT IN ('R') AND dp.name NOT IN ('sys','INFORMATION_SCHEMA')
ORDER BY dp.name;

-- 3.2 Login Oluşturma
USE master;
CREATE LOGIN bike_okuyucu  WITH PASSWORD = 'Okuyucu123!';
CREATE LOGIN bike_satis    WITH PASSWORD = 'Satis123!';
CREATE LOGIN bike_yonetici WITH PASSWORD = 'Yonetici123!';

-- 3.3 Kullanıcılar ve Rol Ataması
USE BikeStores;
CREATE USER bike_okuyucu  FOR LOGIN bike_okuyucu;
CREATE USER bike_satis    FOR LOGIN bike_satis;
CREATE USER bike_yonetici FOR LOGIN bike_yonetici;

EXEC sp_addrolemember 'db_datareader', 'bike_okuyucu';
EXEC sp_addrolemember 'db_datareader', 'bike_satis';
EXEC sp_addrolemember 'db_datawriter', 'bike_satis';
EXEC sp_addrolemember 'db_owner', 'bike_yonetici';

-- 3.4 Sütun Bazında İzin Kısıtlama
DENY SELECT ON sales.customers(phone, email) TO bike_okuyucu;

-- 3.5 Rol Üyeliklerinin Doğrulanması
SELECT dp.name AS KullaniciAdi, rp.name AS RolAdi, rp.type_desc AS RolTuru
FROM sys.database_role_members drm
JOIN sys.database_principals dp ON drm.member_principal_id = dp.principal_id
JOIN sys.database_principals rp ON drm.role_principal_id = rp.principal_id
WHERE dp.name IN ('bike_okuyucu','bike_satis','bike_yonetici')
ORDER BY dp.name;

-- 3.6 İzin Listesi
SELECT pr.name AS KullaniciAdi, pe.state_desc AS IzinDurumu,
       pe.permission_name AS IzinAdi, OBJECT_NAME(pe.major_id) AS NesneAdi
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('bike_okuyucu','bike_satis','bike_yonetici')
ORDER BY pr.name;


/* ------------------------------------------------------------
   4. VERİ ŞİFRELEME (Column-Level Encryption)
   ------------------------------------------------------------ */
USE BikeStores;

-- 4.1 Şifreleme Altyapısı
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKey_Sifre_2026!';

CREATE CERTIFICATE BikeSertifika
WITH SUBJECT = 'BikeStores Veri Sifreleme Sertifikasi';

CREATE SYMMETRIC KEY BikeSimetrikAnahtar
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE BikeSertifika;

-- 4.2 Şifreli Sütun Ekleme
ALTER TABLE sales.customers ADD phone_encrypted VARBINARY(256);

-- 4.3 Verileri Şifreleme
OPEN SYMMETRIC KEY BikeSimetrikAnahtar
DECRYPTION BY CERTIFICATE BikeSertifika;

UPDATE sales.customers
SET phone_encrypted = ENCRYPTBYKEY(KEY_GUID('BikeSimetrikAnahtar'), phone)
WHERE phone IS NOT NULL;

CLOSE SYMMETRIC KEY BikeSimetrikAnahtar;

-- 4.4 Şifreli Veriyi Görüntüleme (anahtarsız)
SELECT TOP 10 customer_id, first_name, phone, phone_encrypted
FROM sales.customers
WHERE phone IS NOT NULL;

-- 4.5 Şifre Çözme (anahtar ile)
OPEN SYMMETRIC KEY BikeSimetrikAnahtar
DECRYPTION BY CERTIFICATE BikeSertifika;

SELECT TOP 10 customer_id, first_name,
       phone AS Orijinal_Telefon,
       phone_encrypted AS Sifreli_Veri,
       CONVERT(VARCHAR, DECRYPTBYKEY(phone_encrypted)) AS Cozulmus_Telefon
FROM sales.customers
WHERE phone IS NOT NULL;

CLOSE SYMMETRIC KEY BikeSimetrikAnahtar;

-- 4.6 Şifreleme Nesnelerini Doğrulama
SELECT name AS SertifikaAdi, subject AS Konu, start_date, expiry_date
FROM sys.certificates WHERE name = 'BikeSertifika';

SELECT name AS AnahtarAdi, algorithm_desc AS Algoritma, key_length AS AnahtarUzunlugu
FROM sys.symmetric_keys WHERE name = 'BikeSimetrikAnahtar';


/* ------------------------------------------------------------
   5. SQL INJECTION TESTLERİ
   ------------------------------------------------------------ */
-- 5.1 Güvensiz Prosedür (Dinamik SQL)
USE BikeStores;
GO
CREATE OR ALTER PROCEDURE sp_MusteriAra_Guvensiz
    @arama VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(500);
    SET @sql = 'SELECT customer_id, first_name, last_name, email
                FROM sales.customers
                WHERE last_name = ''' + @arama + '''';
    PRINT @sql;
    EXEC(@sql);
END;
GO

-- 5.2 Normal Kullanım
EXEC sp_MusteriAra_Guvensiz @arama = 'Burks';

-- 5.3 SQL Injection Saldırısı (tüm tablo dökülür)
EXEC sp_MusteriAra_Guvensiz @arama = ''' OR 1=1 --';

-- 5.4 Güvenli Prosedür (Parametreli sp_executesql)
USE BikeStores;
GO
CREATE OR ALTER PROCEDURE sp_MusteriAra_Guvenli
    @arama VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(500);
    SET @sql = 'SELECT customer_id, first_name, last_name, email
                FROM sales.customers
                WHERE last_name = @p_arama';
    EXEC sp_executesql @sql, N'@p_arama VARCHAR(100)', @p_arama = @arama;
END;
GO

-- 5.5 Güvenli Prosedüre Saldırı (0 sonuç - engellenir)
EXEC sp_MusteriAra_Guvenli @arama = ''' OR 1=1 --';

-- 5.6 Güvenli Prosedürle Normal Kullanım
EXEC sp_MusteriAra_Guvenli @arama = 'Burks';


/* ------------------------------------------------------------
   6. AUDIT LOGLARI (Trigger tabanlı denetim)
   ------------------------------------------------------------ */
-- 6.1 Denetim Kayıt Tablosu
USE BikeStores;
GO
CREATE TABLE dbo.AuditLog (
    audit_id     INT IDENTITY(1,1) PRIMARY KEY,
    islem_turu   VARCHAR(10),
    tablo_adi    VARCHAR(100),
    kullanici    VARCHAR(100),
    islem_zamani DATETIME DEFAULT GETDATE(),
    eski_deger   VARCHAR(500),
    yeni_deger   VARCHAR(500)
);
GO

-- 6.2 Otomatik Denetim Trigger'ı
CREATE OR ALTER TRIGGER trg_Audit_Customers
ON sales.customers
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted)
        INSERT INTO dbo.AuditLog (islem_turu, tablo_adi, kullanici, yeni_deger)
        SELECT 'INSERT', 'sales.customers', SYSTEM_USER,
               CONCAT('ID:', customer_id, ' Ad:', first_name, ' ', last_name)
        FROM inserted;

    IF EXISTS(SELECT * FROM deleted) AND NOT EXISTS(SELECT * FROM inserted)
        INSERT INTO dbo.AuditLog (islem_turu, tablo_adi, kullanici, eski_deger)
        SELECT 'DELETE', 'sales.customers', SYSTEM_USER,
               CONCAT('ID:', customer_id, ' Ad:', first_name, ' ', last_name)
        FROM deleted;

    IF EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
        INSERT INTO dbo.AuditLog (islem_turu, tablo_adi, kullanici, eski_deger, yeni_deger)
        SELECT 'UPDATE', 'sales.customers', SYSTEM_USER,
               CONCAT('ID:', d.customer_id, ' Tel:', d.phone),
               CONCAT('ID:', i.customer_id, ' Tel:', i.phone)
        FROM inserted i JOIN deleted d ON i.customer_id = d.customer_id;
END;
GO

-- 6.3 Test İşlemleri
INSERT INTO sales.customers (first_name, last_name, phone, email, city, state, zip_code)
VALUES ('Test', 'Kullanici', '555-111-2222', 'test@example.com', 'Ankara', 'TR', '06000');

UPDATE sales.customers SET phone = '555-999-8888'
WHERE first_name = 'Test' AND last_name = 'Kullanici';

DELETE FROM sales.customers
WHERE first_name = 'Test' AND last_name = 'Kullanici';

-- 6.4 Denetim Kayıtlarını Görüntüleme
SELECT audit_id, islem_turu, tablo_adi, kullanici, islem_zamani, eski_deger, yeni_deger
FROM dbo.AuditLog
ORDER BY audit_id;
