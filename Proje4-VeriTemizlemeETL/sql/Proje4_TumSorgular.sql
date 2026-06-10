/* ============================================================
   BLM4522 - PROJE 5: VERİ TEMİZLEME VE ETL SÜREÇLERİ
   Veri Kaynağı: Online Retail (UCI)  |  Platform: MS SQL Server (LocalDB)
   Ezgi SANKIR - 21290431
   ============================================================ */

/* ------------------------------------------------------------
   2. EXTRACT - Ham CSV'yi staging tabloya yükleme
   ------------------------------------------------------------ */
-- (Veritabanı: CREATE DATABASE OnlineRetailDB; -- önceden oluşturuldu)
USE OnlineRetailDB;
GO

-- 2.1 Staging (ham) tablo - tüm sütunlar NVARCHAR
CREATE TABLE dbo.Staging_OnlineRetail (
    InvoiceNo NVARCHAR(50), StockCode NVARCHAR(50),
    Description NVARCHAR(255), Quantity NVARCHAR(50),
    InvoiceDate NVARCHAR(50), UnitPrice NVARCHAR(50),
    CustomerID NVARCHAR(50), Country NVARCHAR(100)
);

-- CSV yükleme (tırnak içi virgüller için FORMAT='CSV')
BULK INSERT dbo.Staging_OnlineRetail
FROM 'C:\Users\ezgis\Desktop\BLM4522\OnlineRetail.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',',
      ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);

-- 2.2 Doğrulama
SELECT COUNT(*) AS YuklenenSatir FROM dbo.Staging_OnlineRetail;
SELECT TOP 10 * FROM dbo.Staging_OnlineRetail;


/* ------------------------------------------------------------
   3. VERİ KALİTESİ ANALİZİ
   ------------------------------------------------------------ */
-- 3.1 Genel kalite özeti
SELECT COUNT(*) AS ToplamSatir,
  SUM(CASE WHEN CustomerID IS NULL OR LTRIM(RTRIM(CustomerID))='' THEN 1 ELSE 0 END) AS Eksik_CustomerID,
  SUM(CASE WHEN Description IS NULL OR LTRIM(RTRIM(Description))='' THEN 1 ELSE 0 END) AS Eksik_Description,
  SUM(CASE WHEN TRY_CAST(Quantity AS INT) < 0 THEN 1 ELSE 0 END) AS Negatif_Quantity,
  SUM(CASE WHEN TRY_CAST(UnitPrice AS DECIMAL(10,2)) < 0 THEN 1 ELSE 0 END) AS Negatif_UnitPrice,
  SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) AS Iptal_Faturalar
FROM dbo.Staging_OnlineRetail;

-- 3.2 Eksik değer oranı
SELECT 'CustomerID' AS Sutun,
  SUM(CASE WHEN CustomerID IS NULL OR LTRIM(RTRIM(CustomerID))='' THEN 1 ELSE 0 END) AS EksikSayi,
  CAST(100.0 * SUM(CASE WHEN CustomerID IS NULL OR LTRIM(RTRIM(CustomerID))='' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS EksikYuzde
FROM dbo.Staging_OnlineRetail
UNION ALL
SELECT 'Description',
  SUM(CASE WHEN Description IS NULL OR LTRIM(RTRIM(Description))='' THEN 1 ELSE 0 END),
  CAST(100.0 * SUM(CASE WHEN Description IS NULL OR LTRIM(RTRIM(Description))='' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))
FROM dbo.Staging_OnlineRetail;

-- 3.3 Negatif/uç değer analizi
SELECT
  SUM(CASE WHEN TRY_CAST(Quantity AS INT) < 0 THEN 1 ELSE 0 END) AS Negatif_Miktar,
  SUM(CASE WHEN TRY_CAST(Quantity AS INT) = 0 THEN 1 ELSE 0 END) AS Sifir_Miktar,
  SUM(CASE WHEN TRY_CAST(UnitPrice AS DECIMAL(10,2)) <= 0 THEN 1 ELSE 0 END) AS Sifir_Negatif_Fiyat,
  MIN(TRY_CAST(Quantity AS INT)) AS Min_Miktar,
  MAX(TRY_CAST(Quantity AS INT)) AS Max_Miktar
FROM dbo.Staging_OnlineRetail;

-- 3.4 Yinelenen kayıt analizi
SELECT COUNT(*) AS YinelenenGrupSayisi
FROM (
    SELECT InvoiceNo, StockCode, Quantity, InvoiceDate, UnitPrice, CustomerID, COUNT(*) AS Tekrar
    FROM dbo.Staging_OnlineRetail
    GROUP BY InvoiceNo, StockCode, Quantity, InvoiceDate, UnitPrice, CustomerID
    HAVING COUNT(*) > 1
) AS DuplicateGruplari;

-- 3.5 Ülke dağılımı
SELECT TOP 10 Country, COUNT(*) AS KayitSayisi
FROM dbo.Staging_OnlineRetail
GROUP BY Country
ORDER BY KayitSayisi DESC;


/* ------------------------------------------------------------
   4. TRANSFORM - Veri Temizleme
   ------------------------------------------------------------ */
-- 4.1 Temiz hedef tablo (doğru tipler + türetilmiş TotalPrice)
CREATE TABLE dbo.Clean_OnlineRetail (
    InvoiceNo NVARCHAR(20), StockCode NVARCHAR(20),
    Description NVARCHAR(255), Quantity INT,
    InvoiceDate DATETIME, UnitPrice DECIMAL(10,2),
    CustomerID INT, Country NVARCHAR(100),
    TotalPrice DECIMAL(12,2)
);
GO

-- 4.2 Temizleme kuralları ile aktarım
INSERT INTO dbo.Clean_OnlineRetail
    (InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country, TotalPrice)
SELECT DISTINCT
    LTRIM(RTRIM(InvoiceNo)), LTRIM(RTRIM(StockCode)),
    UPPER(LTRIM(RTRIM(Description))),
    TRY_CAST(Quantity AS INT), TRY_CAST(InvoiceDate AS DATETIME),
    TRY_CAST(UnitPrice AS DECIMAL(10,2)), TRY_CAST(CustomerID AS INT),
    LTRIM(RTRIM(Country)),
    TRY_CAST(Quantity AS INT) * TRY_CAST(UnitPrice AS DECIMAL(10,2))
FROM dbo.Staging_OnlineRetail
WHERE InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL AND LTRIM(RTRIM(CustomerID)) <> ''
  AND Description IS NOT NULL AND LTRIM(RTRIM(Description)) <> ''
  AND TRY_CAST(Quantity AS INT) > 0
  AND TRY_CAST(UnitPrice AS DECIMAL(10,2)) > 0;

-- 4.3 Öncesi/sonrası satır sayısı
SELECT
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail) AS Ham_Satir,
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail)   AS Temiz_Satir,
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail) -
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail)   AS Cikarilan_Satir;

-- 4.4 Temiz veriden örnek
SELECT TOP 10 InvoiceNo, StockCode, Description, Quantity,
       InvoiceDate, UnitPrice, CustomerID, Country, TotalPrice
FROM dbo.Clean_OnlineRetail;


/* ------------------------------------------------------------
   5. VERİ DÖNÜŞTÜRME VE ZENGİNLEŞTİRME
   ------------------------------------------------------------ */
-- 5.1 Tarih bileşenlerini ayrıştırma
ALTER TABLE dbo.Clean_OnlineRetail ADD Yil INT, Ay INT, AyAdi NVARCHAR(20);
GO
UPDATE dbo.Clean_OnlineRetail
SET Yil = YEAR(InvoiceDate), Ay = MONTH(InvoiceDate),
    AyAdi = DATENAME(MONTH, InvoiceDate);

SELECT TOP 10 InvoiceNo, InvoiceDate, Yil, Ay, AyAdi, TotalPrice
FROM dbo.Clean_OnlineRetail;

-- 5.2 Aylık satış özeti
SELECT Yil, Ay, AyAdi,
       COUNT(DISTINCT InvoiceNo) AS FaturaSayisi,
       SUM(Quantity) AS ToplamMiktar,
       CAST(SUM(TotalPrice) AS DECIMAL(14,2)) AS ToplamCiro
FROM dbo.Clean_OnlineRetail
GROUP BY Yil, Ay, AyAdi
ORDER BY Yil, Ay;

-- 5.3 En çok satan ürünler
SELECT TOP 10 StockCode, Description,
       SUM(Quantity) AS ToplamSatilanAdet,
       CAST(SUM(TotalPrice) AS DECIMAL(14,2)) AS ToplamCiro
FROM dbo.Clean_OnlineRetail
GROUP BY StockCode, Description
ORDER BY ToplamCiro DESC;

-- 5.4 Ülke bazında satış
SELECT TOP 10 Country,
       COUNT(DISTINCT CustomerID) AS MusteriSayisi,
       COUNT(DISTINCT InvoiceNo)  AS FaturaSayisi,
       CAST(SUM(TotalPrice) AS DECIMAL(14,2)) AS ToplamCiro
FROM dbo.Clean_OnlineRetail
GROUP BY Country
ORDER BY ToplamCiro DESC;


/* ------------------------------------------------------------
   6. LOAD - Data Mart Yükleme
   ------------------------------------------------------------ */
-- 6.1 Hedef data mart tabloları
CREATE TABLE dbo.Mart_AylikSatis (
    Yil INT, Ay INT, AyAdi NVARCHAR(20),
    FaturaSayisi INT, ToplamMiktar INT, ToplamCiro DECIMAL(14,2)
);
CREATE TABLE dbo.Mart_UlkeSatis (
    Country NVARCHAR(100), MusteriSayisi INT,
    FaturaSayisi INT, ToplamCiro DECIMAL(14,2)
);
GO

-- 6.2 Aylık satış data mart yükleme
INSERT INTO dbo.Mart_AylikSatis (Yil, Ay, AyAdi, FaturaSayisi, ToplamMiktar, ToplamCiro)
SELECT Yil, Ay, AyAdi, COUNT(DISTINCT InvoiceNo), SUM(Quantity),
       CAST(SUM(TotalPrice) AS DECIMAL(14,2))
FROM dbo.Clean_OnlineRetail
GROUP BY Yil, Ay, AyAdi;

-- 6.3 Ülke satış data mart yükleme
INSERT INTO dbo.Mart_UlkeSatis (Country, MusteriSayisi, FaturaSayisi, ToplamCiro)
SELECT Country, COUNT(DISTINCT CustomerID), COUNT(DISTINCT InvoiceNo),
       CAST(SUM(TotalPrice) AS DECIMAL(14,2))
FROM dbo.Clean_OnlineRetail
GROUP BY Country;

-- 6.4 Hedef tabloları doğrulama
SELECT 'Mart_AylikSatis' AS HedefTablo, COUNT(*) AS SatirSayisi FROM dbo.Mart_AylikSatis
UNION ALL
SELECT 'Mart_UlkeSatis', COUNT(*) FROM dbo.Mart_UlkeSatis;

SELECT * FROM dbo.Mart_AylikSatis ORDER BY Yil, Ay;


/* ------------------------------------------------------------
   7. VERİ KALİTESİ RAPORU
   ------------------------------------------------------------ */
-- 7.1 Öncesi/sonrası karşılaştırma
SELECT 'Toplam Satır' AS Metrik,
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail) AS Temizleme_Oncesi,
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail)   AS Temizleme_Sonrasi
UNION ALL
SELECT 'Eksik CustomerID',
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail WHERE CustomerID IS NULL OR LTRIM(RTRIM(CustomerID))=''),
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail WHERE CustomerID IS NULL)
UNION ALL
SELECT 'Eksik Description',
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail WHERE Description IS NULL OR LTRIM(RTRIM(Description))=''),
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail WHERE Description IS NULL OR Description='')
UNION ALL
SELECT 'Negatif/Sıfır Miktar',
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail WHERE TRY_CAST(Quantity AS INT) <= 0),
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail WHERE Quantity <= 0)
UNION ALL
SELECT 'Negatif/Sıfır Fiyat',
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail WHERE TRY_CAST(UnitPrice AS DECIMAL(10,2)) <= 0),
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail WHERE UnitPrice <= 0)
UNION ALL
SELECT 'İptal Faturalar',
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail WHERE InvoiceNo LIKE 'C%'),
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail WHERE InvoiceNo LIKE 'C%');

-- 7.2 Veri kullanım oranı
SELECT
    (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail) AS Ham_Kayit,
    (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail)   AS Temiz_Kayit,
    CAST(100.0 * (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail)
         / (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail) AS DECIMAL(5,2)) AS Veri_Kullanim_Yuzdesi,
    CAST(100.0 * ((SELECT COUNT(*) FROM dbo.Staging_OnlineRetail) - (SELECT COUNT(*) FROM dbo.Clean_OnlineRetail))
         / (SELECT COUNT(*) FROM dbo.Staging_OnlineRetail) AS DECIMAL(5,2)) AS Temizlenen_Yuzde;

-- 7.3 Temiz veri bütünlük kontrolü
SELECT
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Kalan_Eksik_Musteri,
    SUM(CASE WHEN Description IS NULL OR Description='' THEN 1 ELSE 0 END) AS Kalan_Bos_Aciklama,
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS Kalan_Negatif_Miktar,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS Kalan_Negatif_Fiyat,
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS Kalan_Gecersiz_Tarih
FROM dbo.Clean_OnlineRetail;
