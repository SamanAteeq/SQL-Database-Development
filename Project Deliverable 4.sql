Use [IMT_PROJ_2075472]
go

--1) Stored Procedure

--Creating procedures to be used in nested stored procedure for inserting rows in tblDrink

CREATE PROCEDURE sp_getCupSizeId @Cupsize VARCHAR(20)
	,@cupsizeid INT OUT
AS
BEGIN
	SET @cupsizeid = (
			SELECT Cupsize_ID
			FROM tblCupsize
			WHERE Cupsize = @Cupsize
			)
END
GO

CREATE PROCEDURE sp_getTypeDrinkId @TypeDrinkName VARCHAR(20)
	,@typedrinkid INT OUT
AS
BEGIN
	SET @typedrinkid = (
			SELECT Type_Drink_ID
			FROM tblType_Drink
			WHERE Type_Drink_Name = @TypeDrinkName
			)
END
GO

CREATE PROCEDURE sp_getSubTypeDrinkId @SubTypeDrinkName VARCHAR(20)
	,@subtypedrinkid INT OUT
AS
BEGIN
	SET @subtypedrinkid = (
			SELECT SubType_Drink_ID
			FROM tblSubType_Drink
			WHERE SubType_Drink_Name = @SubTypeDrinkName
			)
END
GO

--Creating lookup stored procedure to check if the inserted row exists or not

CREATE PROCEDURE sp_getdrinkid @drinkName VARCHAR(30)
	,@drinkid INT OUT
AS
BEGIN
	DECLARE @status INT = 0;

	BEGIN TRY
		(
				SELECT @drinkid = DrinkId
				FROM tblDrink
				WHERE Drink_Name = @DrinkName
				);

		SET @status = + 1;
	END TRY

	BEGIN CATCH
		SET @status = - 1
	END CATCH

	RETURN @status
END
GO

--Stored Procedure for Inserting records into tblDrink leveraging Nested Stored Procedures

CREATE PROCEDURE sp_inserttblDrink @DrinkName VARCHAR(30)
	,@Price NUMERIC(4, 2)
	,@Drink_Type VARCHAR(20)
	,@Drink_SubType VARCHAR(20)
	,@Cupsizename VARCHAR(20)
	,@newdrinkid INT
AS
BEGIN
	DECLARE @drinktype_id INT
		,@drinksubtype_id INT
		,@cupsize_id INT

	EXECUTE sp_getCupSizeId @Cupsize = @Cupsizename
		,@cupsizeid = @cupsize_id OUT

	IF @cupsize_id IS NULL
	BEGIN
		PRINT '@cupsize_id is NULL and will fail during the INSERT transaction; check spelling of all parameters';

		THROW 56676
			,'@cupsize_id cannot be NULL; statement is terminating'
			,1;
	END

	EXECUTE sp_getTypeDrinkId @TypeDrinkName = @Drink_Type
		,@typedrinkid = @drinktype_id OUT

	IF @drinktype_id IS NULL
	BEGIN
		PRINT '@drinktype_id is NULL and will fail during the INSERT transaction; check spelling of all parameters';

		THROW 56676
			,'@drinktype_id cannot be NULL; statement is terminating'
			,1;
	END

	EXECUTE sp_getSubTypeDrinkId @SubTypeDrinkName = @Drink_SubType
		,@subtypedrinkid = @drinksubtype_id OUT

	IF @drinksubtype_id IS NULL
	BEGIN
		PRINT '@drinktype_id is NULL and will fail during the INSERT transaction; check spelling of all parameters';

		THROW 56676
			,'@drinktype_id cannot be NULL; statement is terminating'
			,1;
	END

	DECLARE @status INT = 0
		,@drinkid INT = NULL;

	BEGIN TRY
		EXEC @status = sp_getdrinkid @drinkName = @DrinkName
			,@drinkid = @drinkid OUT;

		IF @status = 1
			AND @drinkid IS NULL
		BEGIN
			BEGIN TRANSACTION

			INSERT INTO tblDrink(
				Drink_Name
				,DrinkType_ID
				,DrinkSubType_ID
				,Cupsize_ID
				,Price
				)
			VALUES (
				@DrinkName
				,@drinktype_id
				,@drinksubtype_id
				,@cupsize_id
				,@Price
				)

			COMMIT TRANSACTION

			SET @newdrinkid = @@identity;
			SET @status = + 1;
		END
		ELSE
			RAISERROR (
					'Drink Already exists, see DrinkID '
					,15
					,1
					);
			RETURN
	END TRY

	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION

		SET @status = - 1

		DECLARE @Message NVARCHAR(100);

		SET @Message = ERROR_MESSAGE() + Cast(@drinkid AS VARCHAR(10));

		RAISERROR (
				@Message
				,15
				,1
				);
	    Return
	END CATCH

	RETURN @status
END
GO

--Creating procedures to be used in nested stored procedure for inserting rows in tblOrder

CREATE PROCEDURE Sp_getdrinkid @drinkName VARCHAR(30),
                               @drinkid   INT out
AS
  BEGIN
      DECLARE @status INT = 0;

      BEGIN try
          (SELECT @drinkid = drinkid
           FROM   tbldrink
           WHERE  drink_name = @DrinkName);

          SET @status = +1;
      END try

      BEGIN catch
          SET @status = -1
      END catch

      RETURN @status
  END

go

CREATE PROCEDURE Sp_getcustomerid @customerFname VARCHAR(50),
                                  @customerLname VARCHAR(50),
                                  @customerid    INT out
AS
  BEGIN
      SET @customerid= (SELECT customer_id
                        FROM   [dbo].[tblcustomer]
                        WHERE  customer_fname = @customerFname
                               AND customer_lname = @customerLname)
  END

go

CREATE PROCEDURE Sp_getmilkid @Milkname VARCHAR(20),
                              @milkid   INT out
AS
  BEGIN
      SET @milkid= (SELECT milk_id
                    FROM   tblmilk
                    WHERE  milk_name = @Milkname)
  END

go

CREATE PROCEDURE Sp_getsyrupid @Syrupname VARCHAR(20),
                               @syrupid   INT out
AS
  BEGIN
      SET @syrupid= (SELECT syrup_id
                     FROM   tblsyrup
                     WHERE  syrup_name = @Syrupname)
  END

go

CREATE PROCEDURE Sp_getcustomizerid @Customizername VARCHAR(20),
                                    @customizerid   INT out
AS
  BEGIN
      SET @customizerid= (SELECT customizer_id
                          FROM   tblcustomizer
                          WHERE  customizer = @Customizername)
  END

go

--Stored Procedure for Inserting records into tblOrder leveraging Nested Stored Procedures
Create PROCEDURE Sp_inserttblorder @Quantity INT,
                                   @OrderDate         DATETIME,
                                   @customerFirstname VARCHAR(50),
                                   @customerLastname  VARCHAR(50),
                                   @DrinkName         VARCHAR(50),
                                   @Milk              VARCHAR(20),
                                   @Syrup             VARCHAR(20),
                                   @Customizer        VARCHAR(30)
AS
  BEGIN
      DECLARE @customerid   INT,
              @drinkid      INT,
              @milkid       INT,
              @syrupid      INT,
              @customizerid INT

      EXEC Sp_getcustomerid
        @customerFname=@customerFirstname,
        @customerLname= @customerLastname,
        @customerid=@customerid out

      IF( @customerid IS NULL )
        BEGIN
            PRINT
'@customerid is NULL and will fail during the INSERT transaction; check spelling of all parameters'
    ;

    THROW 56676, '@customerid cannot be NULL; statement is terminating', 1;
END

    EXEC [dbo].[Sp_getdrinkid]
      @drinkName= @DrinkName,
      @drinkid= @drinkid out

    IF( @drinkid IS NULL )
      BEGIN
          PRINT
'@drinkid is NULL and will fail during the INSERT transaction; check spelling of all parameters'
    ;

    THROW 56676, '@drinkid cannot be NULL; statement is terminating', 1;
END

    EXEC Sp_getmilkid
      @Milkname= @Milk,
      @milkid= @milkid out

    EXEC Sp_getsyrupid
      @Syrupname= @Syrup,
      @syrupid= @syrupid out

    EXEC Sp_getcustomizerid
      @Customizername=@Customizer,
      @customizerid=@customizerid out

    DECLARE @returncode INT =0

    BEGIN try
        BEGIN TRANSACTION

        INSERT INTO tblorder
                    (customer_id,
                     drink_id,
                     milk_id,
                     syrup_id,
                     customizer_id,
                     quantity,
                     orderdate)
                    
        VALUES      (@customerid,
                     @drinkid,
                     @milkid,
                     @syrupid,
                     @customizerid,
                     @Quantity,
                     @OrderDate)
                   

        COMMIT TRANSACTION

        SET @returncode=+1
    END try

    BEGIN catch
        IF @@trancount > 0
          ROLLBACK TRANSACTION

        PRINT Error_message()

        SET @returncode=-1
    END catch

    RETURN @returncode
END

go 

--2) Business Rule
	
--Business Rule 1: Price of the Drinks can not be negative

Alter Table [dbo].[tblDrink]
Add Constraint NonNegativePriceValue
Check (Price>0)

--Business Rule 2: Frappuccinos, Lemonade, etc. can not be hot, 
--hot chocolate, white hot chocolate, cappuccino, etc. (Cold Foam not available at Center Table) can not be cold
--Other coffee can be hot or iced

Alter Table [dbo].[tblDrink] with nocheck
Add Constraint DrinkHotORCold Check
(
Case 
when ([Drink_Name] in ('Hot Chocolate','Peppermint Hot Chocolate''White Hot Chocolate','Freshly Brewed Coffee','Cappuccino','London Fog Tea Latte') or [Drink_Name] like '%Tea') and [DrinkSubType_ID]=1 then 1 
when ([Drink_Name] in ('Passion Tea Lemonade','Black Tea Lemonade', 'Green Tea Lemonade', 'Iced Coffee', 'Cold Brew') or [Drink_Name] like '%Frappuccino%') and [DrinkSubType_ID]=2 then 1 
when ([Drink_Name] like '%Mocha' or [Drink_Name] like '%Latte' or [Drink_Name] in ('Caramel Macchiato','Americano', 'Expresso')) and [DrinkSubType_ID] in (1,2) then 1
else 0 end=1)

--Checking if check constraint is working properly: When tried to insert 2 in DrinkSubType_ID, 
--insertion failed but was successful when inserted 1 in DrinkSubType_ID

Insert into [dbo].[tblDrink] (Drink_Name, DrinkType_ID, DrinkSubType_ID, Cupsize_ID, Price)
values ('Hot Chocolate',1,1,1,5.25)

--Computed Column

--Creating function for calculating paid amount of purchased coffee

Create function CustomCoffeePriceCalculation (@drinkid int, @milkid varchar(20), @syrupid varchar(30), @quantity int)
returns numeric(8,2) 
with schemabinding 
as
begin
declare @drinkprice numeric(4,2), @milkprice numeric(3,2) , @syruprice numeric(3,2), @TotalCoffeePrice numeric(8,2),@TotalCoffeePricewithtax numeric(8,2);
select @drinkprice = Price from [dbo].[tblDrink] where DrinkID=@drinkid;
if @milkid is not null begin select @milkprice = Milk_Price from [dbo].[tblMilk] where Milk_ID=@milkid end else select @milkprice=0;
if @syrupid is not null begin select @syruprice = Syrup_Price from [dbo].[tblSyrup] where Syrup_ID=@syrupid end else select @syruprice=0;
select @TotalCoffeePrice = @drinkprice+@milkprice+@syruprice;
select @TotalCoffeePricewithtax=@TotalCoffeePrice*1.10* @quantity;   --10% sales tax
return @TotalCoffeePricewithtax ;
end;
go

--Computed Column 1: Adding Computed column: Total Sales 

Alter Table [dbo].[tblOrder]
add TotalSales as dbo.CustomCoffeePriceCalculation(Drink_ID, Milk_ID, Syrup_ID, Quantity) ;
go;

--Creating Function for Getting Customers' full name

Create function GetfullNameCustomer (@firstname varchar(50), @lastname varchar(50))
returns varchar(100)
as 
begin
declare @fullname varchar(100);
select @fullname= @firstname+ ' ' + @lastname from tblCustomer ;
return @fullname;
end;
go

--Computed Column 2: Adding a column for customer's full name
Alter table [dbo].[tblCustomer]
Add [Full Name] as dbo.GetfullNameCustomer(Customer_Fname, Customer_Lname)

--4) Queries

--Which is the most popular drink size: Tall, Venti, or Grande, Milk, & Syrup

select top 3 c.Cupsize, m.Milk_Name, s.Syrup_Name from [dbo].[tblOrder] o join tblDrink d on o.Drink_ID=d.DrinkID
join tblCupsize c on c.Cupsize_ID=d.Cupsize_ID
join tblSyrup s on s.Syrup_ID=o.Syrup_ID
join tblMilk m on m.Milk_ID=o.Milk_ID group by c.Cupsize,m.Milk_Name, s.Syrup_Name order by sum(o.Quantity) desc

--Calculate MTD, YTD sales of Coffee at Quench

Select Month(OrderDate) as 'Month', Sum(TotalSales) as 'MTDSales' from tblOrder where Month(OrderDate)= Month(GetDate())
Group by Month(OrderDate)


Select Year(OrderDate) as 'Year', Sum(TotalSales) as 'YTDSales' from tblOrder where Year(OrderDate)= Year(GetDate())
Group by Year(OrderDate)
