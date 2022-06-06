
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RAP_YILLIKIZIN]

	@LoginID int = NULL,
	@Ad nvarchar(50) =null,
	@Soyad nvarchar(50)=null,
	@FirmaAdi nvarchar(50)=null,
	@BolgeAdi nvarchar(50)=null,
	@PozisyonAdi nvarchar(50)=null,
	@GorevAdi nvarchar(50)=null,
	@YakaAdi nvarchar(50)=null,
	@TarihBas datetime=null,
	@TarihBit datetime = null


AS
BEGIN
	
	declare @tmp table (PersonelId int, Tarih smalldatetime, Kidem int, Hak int, Yas int,HakEx int, KullanilanYillikIzin int, PlanlananIzin int, Kalan int, KidemEx int, YillikIzinHakTarihi smalldatetime, IzinDevir int)
	DECLARE   @PersonelID int                           
	declare @GirisTarih smalldatetime 
	declare @DogumTarih smalldatetime
	declare @Tarih smalldatetime 
	DECLARE @Tarih2 smalldatetime
	declare @Gun int 
	DECLARE @Hak int 
	DECLARE @HakEx int
	declare @IzinDevir int 
	DECLARE @KullanilanYillikIzin int 
	DECLARE @PlanlananIzin int 
	DECLARE @Kalan int 
	DECLARE @Kidem int
	DECLARE @Zaman as smalldatetime

	select @Zaman = cast(convert(varchar,getdate(),112) as smalldatetime)
	
	DECLARE @ID int
	DECLARE contact_cursor CURSOR FOR
	SELECT P.ID 
	FROM TBL_SICIL p with(nolock) 
	where CIKIS_TARIHI is null and isdate(GIRIS_TARIHI)=1
		--and s.Ad like '' + @Ad + '%'
		--and s.Soyad like '' + @Soyad + '%'
--		and datediff(year,DogumTarih, getdate())>50

	OPEN contact_cursor;
	FETCH NEXT FROM contact_cursor INTO @ID;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		      
		select @Hak=0, @HakEx=0, @Kidem=0
		select @PersonelID=@ID 
		
		
		select @GirisTarih = GIRIS_TARIHI, @DogumTarih=isnull(DOGUM_TARIHI,@Zaman) from TBL_SICIL where ID=@ID--left join Per_EkBilgi peb on p.Id = peb.PersonelId where p.Id=@PersonelID
		set @Tarih=@GirisTarih
		
		select @Gun=datediff(year,@GirisTarih,@Zaman)--Kıdem.
		
		select @Tarih2=dateadd(year,@Gun,@GirisTarih)--Kıdem Tarihi
		
		
		select @IzinDevir=0
		if exists(select * from  TBL_SICIL where TBL_SICIL.IzinDevir > 0 and TBL_SICIL.ID=@PersonelID)
		begin
			select @IzinDevir=IzinDevir from TBL_SICIL where  IzinDevir > 0 and  TBL_SICIL.ID=@PersonelID
		end
		
		select @KullanilanYillikIzin = 0
		select @KullanilanYillikIzin = count(*) from TBL_IZINLER izn inner join TBL_IZINTIP Izt on izn.TIP_ID=Izt.ID where Izt.YILLIKIZIN=1  and izn.SICIL_ID=@PersonelID and Tarih<=@Zaman AND izn.IS_ACTIVE=1 
		
		select @PlanlananIzin = 0
		select @PlanlananIzin = count(*) from TBL_IZINLER izn inner join TBL_IZINTIP Izt on izn.TIP_ID=Izt.ID where Izt.YILLIKIZIN=1 and izn.SICIL_ID=@PersonelID and year(Tarih)=year(@Zaman) and Tarih>@Zaman AND izn.IS_ACTIVE=1
		
		declare @KidemSay int, @eksi int
		set @KidemSay = 0
		while @Tarih < @Tarih2 
		begin
			
			set    @KidemSay = @KidemSay + 1
			select @Tarih = dateadd(year,@KidemSay,@GirisTarih)
			select @DogumTarih = isnull(DOGUM_TARIHI,@Tarih) from TBL_SICIL where ID=@ID --inner join Per_EkBilgi ekb on Personel.Id = ekb.PersonelId where Personel.Id=@PersonelID
			
			set @eksi = 0
			if @Tarih<'2003-06-10'
			begin
				set @eksi = 2
			end
			
			if (@Tarih<=@Zaman)
			begin
				
				if (@KidemSay between 1 and 5)
				begin
					set @HakEx = 14
					if datediff(year,@DogumTarih,@Tarih)>=50
					begin
						set @HakEx = 20
					end
				end
				if (@KidemSay between 6 and 14)
				begin
					set @HakEx = 20
				end
				if (@KidemSay>=15)
				begin
					set @HakEx = 26
				end
				set @HakEx=@HakEx-@eksi
				
				set @Hak = @Hak + @HakEx 
			    
				set @HakEx = @HakEx 
				
				--insert into @tmp (SicilID, Tarih, Kidem, Hak, HakEx, Yas, flag)
				--select @ID SicilID, @Tarih Tarih, @KidemSay KidemSay, @Hak DevredenIzinGunu, @HakEx Hak, datediff(year,@DogumTarih,@Tarih) Yas, 0
				
			end
			
		end
		
		select @Kalan = 0
		select @Kalan = @Hak-@KullanilanYillikIzin-@PlanlananIzin-@IzinDevir
		--set @Kalan = ISNULL(@Kalan,0)	
			
		insert into @tmp (PersonelId, Tarih, Kidem, Hak, HakEx, KullanilanYillikIzin, PlanlananIzin, Kalan, KidemEx, YillikIzinHakTarihi, IzinDevir)
		select @PersonelID PersonelId, @Tarih Tarih, ISNULL(@KidemSay,0) KidemSay, @Hak DevredenIzinGunu, @HakEx Hak, @KullanilanYillikIzin KullanilanYillikIzin, @PlanlananIzin PlanlananIzin, @Kalan Kalan, @Gun+@Kidem KidemEx, @Tarih2 YillikIzinHakTarihi, @IzinDevir IzinDevir
		
	FETCH NEXT FROM contact_cursor INTO @ID;
	END
	
	CLOSE contact_cursor;
	DEALLOCATE contact_cursor;
	
	--select * from @tmp
	
			select SICIL_NO,
			F.ID as FirmaID, 
			f.ADI Firma,
			b.ID as BolgeID, 
			b.ADI BolgeAd,
			p.Ad,
			P.Soyad,
			Poz.ADI as PozisyonAd, Poz.Id as PozisyonID, 
			G.ADI as GorevAd, G.ID as GorevID,
			Y.ADI as YakaAd, Y.ID as YakaID,
			p.GIRIS_TARIHI as GirisTarihi, 
			p.DOGUM_TARIHI,
			YillikIzinHakTarihi,  Hak, @IzinDevir IzinDevir, yas, Kalan, Kidem,KullanilanYillikIzin,PlanlananIzin, HakEx
			--ISNULL(Kalan,0)as Kalan ,ISNULL(KidemEx,0) as Kidem,KullanilanYillikIzin,PlanlananIzin
			from @tmp t 
			left join TBL_SICIL p with(nolock) on t.PersonelId = p.Id 
			left join TBL_FIRMA f with(nolock)  on f.Id=P.FIRMA_ID 
			left join TBL_BOLGE b with(nolock)  on b.Id=p.BOLGE_ID
			left join TBL_POZISYON as Poz on Poz.Id=P.POZISYON_ID 
			left join TBL_GOREV G with(nolock) on g.ID=p.GOREV_ID
			left join TBL_YAKA Y with(nolock) on Y.ID=p.YAKA_ID
			--  exec RAP_YILLIKIZIN 
	
	WHERE

	ISNULL(p.AD,'') LIKE IIF(@Ad IS NULL, '%%','%'+@Ad+'%')
	AND ISNULL(p.Soyad,'') LIKE IIF(@Soyad IS NULL, '%%','%'+@Soyad+'%')
	AND ISNULL(f.ADI,'') LIKE IIF(@FirmaAdi IS NULL, '%%','%'+@FirmaAdi+'%')
	AND ISNULL(B.ADI,'') LIKE IIF(@BolgeAdi IS NULL, '%%','%'+@BolgeAdi+'%')
	AND ISNULL(Poz.ADI,'') LIKE IIF(@PozisyonAdi IS NULL, '%%','%'+@PozisyonAdi+'%')
	AND ISNULL(G.ADI,'') LIKE IIF(@GorevAdi IS NULL, '%%','%'+@GorevAdi+'%')
	AND ISNULL(Y.ADI,'') LIKE IIF(@YakaAdi IS NULL, '%%','%'+@YakaAdi+'%')
	--AND	CONVERT(DATE,izn.TARIH) >= IIF(@TarihBas IS NULL ,convert(DATE,'1900-01-01'),convert(date,@TarihBas))
	--AND CONVERT(DATE,izn.TARIH) <= IIF(@TarihBit IS NULL ,convert(DATE,'2100-01-01'),convert(date,@TarihBit))
	
	
		order by p.Id
		
END

--  exec RAP_YILLIKIZIN  '7'
