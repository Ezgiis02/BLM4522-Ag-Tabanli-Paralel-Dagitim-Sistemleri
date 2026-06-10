# ============================================================
# BLM4522 - PROJE 7: PowerShell ile Otomatik Yedekleme
# Veritabani: pubs | Platform: MS SQL Server (LocalDB)
# Ezgi SANKIR - 21290431
# ============================================================

# --- Ayarlar ---
$Sunucu       = "(localdb)\MSSQLLocalDB"
$Veritabani   = "pubs"
$YedekKlasoru = "C:\Backup"
$Tarih        = Get-Date -Format "yyyyMMdd_HHmmss"
$YedekDosya   = "$YedekKlasoru\pubs_PS_$Tarih.bak"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " PowerShell Otomatik Yedekleme Basliyor" -ForegroundColor Cyan
Write-Host " Zaman: $(Get-Date)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# --- Yedekleme komutu ---
$BackupSorgu = "BACKUP DATABASE [$Veritabani] TO DISK = N'$YedekDosya' " +
               "WITH FORMAT, NAME = N'pubs PowerShell Otomatik Yedek';"

# --- sqlcmd ile yedegi al ---
try {
    sqlcmd -S $Sunucu -d master -Q $BackupSorgu -b

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[BASARILI] Yedek alindi: $YedekDosya" -ForegroundColor Green

        # Log tablosuna PowerShell yedegini de kaydet
        $LogSorgu = "INSERT INTO pubs.dbo.YedeklemeLog " +
                    "(VeritabaniAdi, YedekTuru, DosyaYolu, BaslangicZamani, BitisZamani, Durum, Mesaj) " +
                    "VALUES ('pubs','FULL-PS','$YedekDosya', GETDATE(), GETDATE(), 'BASARILI', 'PowerShell ile alindi');"
        sqlcmd -S $Sunucu -d master -Q $LogSorgu
    }
    else {
        Write-Host "`n[BASARISIZ] Yedekleme hatasi!" -ForegroundColor Red
    }
}
catch {
    Write-Host "`n[HATA] $($_.Exception.Message)" -ForegroundColor Red
}

# --- Diskteki yedek dosyalarini listele ---
Write-Host "`n--- C:\Backup klasorundeki pubs yedekleri ---" -ForegroundColor Yellow
Get-ChildItem -Path $YedekKlasoru -Filter "pubs_*.bak" |
    Select-Object Name,
                  @{Name="BoyutKB"; Expression={[math]::Round($_.Length/1KB,1)}},
                  LastWriteTime |
    Format-Table -AutoSize

Write-Host "Yedekleme islemi tamamlandi." -ForegroundColor Cyan
