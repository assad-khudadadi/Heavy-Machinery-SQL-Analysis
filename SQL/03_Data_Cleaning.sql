/*==============================================================
  Heavy Machinery Sales Analysis — Data Cleaning
==============================================================

Purpose:
Correct the data-quality issues identified during initial
data profiling and prepare the dataset for business analysis.

Cleaning Steps:
1. Correct the imported Countries by Continents reference table.
2. Correct the HMCalendar SortYM column.
3. Correct the HMCalendar Quarter column.
4. Standardize country names.
5. Populate missing continent values in HMStores.
6. Correct a misspelled store city name.
7. Validate the cleaned data.

Execution Note:
This script is designed to be executed once on the original
imported dataset.

Some operations rename, drop, or recreate columns. Therefore,
re-executing the complete script on an already cleaned database
may cause errors.

Important:
Review the target database before executing this script.
==============================================================*/

set nocount on;



/*==============================================================
  1. Correct the Countries by Continents Reference Table
  --------------------------------------------------------------
  The Excel header row was imported as data, while the imported
  columns were assigned the generic names Column1 and Column2.
==============================================================*/

-- Preview the imported reference table.
select top (5)
    *
from dbo.[Countries by Continents];

-- Rename the imported columns.
exec sys.sp_rename
    'dbo.[Countries by Continents].Column1',
    'Continent',
    'column';

exec sys.sp_rename
    'dbo.[Countries by Continents].Column2',
    'Country',
    'column';

-- Verify that the original header row exists as a data record.
select
    Continent,
    Country
from dbo.[Countries by Continents]
where Continent = 'Continent'
  and Country = 'Country';

-- Remove the incorrectly imported header row.
delete from dbo.[Countries by Continents]
where Continent = 'Continent'
  and Country = 'Country';

-- Validate the corrected column names.
select
    column_name,
    data_type,
    character_maximum_length
from information_schema.columns
where table_schema = 'dbo'
  and table_name = 'Countries by Continents'
order by
    ordinal_position;

-- Confirm that the imported header row was removed.
select
    Continent,
    Country
from dbo.[Countries by Continents]
where Continent = 'Continent'
   or Country = 'Country';




/*==============================================================
  2. Correct the HMCalendar SortYM Column
  --------------------------------------------------------------
  SortYM was incorrectly imported as a date column. In the
  original source file, it represents a six-digit YYYYMM value.
==============================================================*/

-- Review the imported column definition.
select
    column_name,
    data_type
from information_schema.columns
where table_schema = 'dbo'
  and table_name = 'HMCalendar'
  and column_name = 'SortYM';

-- Preview the current value and the expected YYYYMM value.
select top (10)
    Year,
    MonthNo,
    SortYM as CurrentSortYM,
    cast
    (
        concat
        (
            Year,
            right('0' + cast(MonthNo as varchar(2)), 2)
        )
        as int
    ) as ExpectedSortYM
from dbo.HMCalendar
order by
    Year,
    MonthNo,
    Date;

-- Remove the incorrectly imported column.
alter table dbo.HMCalendar
drop column SortYM;

-- Recreate SortYM with the correct data type.
alter table dbo.HMCalendar
add SortYM int;

-- Populate SortYM in YYYYMM format.
update dbo.HMCalendar
set SortYM =
    cast
    (
        concat
        (
            Year,
            right('0' + cast(MonthNo as varchar(2)), 2)
        )
        as int
    );

-- Validate the corrected data type.
select
    column_name,
    data_type
from information_schema.columns
where table_schema = 'dbo'
  and table_name = 'HMCalendar'
  and column_name = 'SortYM';

-- Validate the corrected values.
select
    Date,
    Year,
    MonthNo,
    SortYM
from dbo.HMCalendar
where SortYM is null
   or SortYM <>
      cast
      (
          concat
          (
              Year,
              right('0' + cast(MonthNo as varchar(2)), 2)
          )
          as int
      );



/*==============================================================
  3. Correct the HMCalendar Quarter Column
  --------------------------------------------------------------
  Quarter was incorrectly imported as a money column containing
  numeric values such as 1.00, 2.00, 3.00, and 4.00.

  The expected values are Q1, Q2, Q3, and Q4.
==============================================================*/

-- Review the imported Quarter data type.
select
    column_name,
    data_type
from information_schema.columns
where table_schema = 'dbo'
  and table_name = 'HMCalendar'
  and column_name = 'Quarter';

-- Preview the current and expected Quarter values.
select distinct
    Quarter as CurrentQuarter,
    concat('Q', cast(Quarter as int)) as ExpectedQuarter
from dbo.HMCalendar
order by
    CurrentQuarter;

-- Add a temporary column with the correct data type.
alter table dbo.HMCalendar
add CorrectQuarter nvarchar(2);

-- Populate the corrected Quarter values.
update dbo.HMCalendar
set CorrectQuarter =
    concat
    (
        'Q',
        cast(Quarter as int)
    );

-- Validate the temporary column before replacing Quarter.
select distinct
    Quarter as OriginalQuarter,
    CorrectQuarter
from dbo.HMCalendar
order by
    OriginalQuarter;

-- Remove the incorrectly imported Quarter column.
alter table dbo.HMCalendar
drop column Quarter;

-- Rename the corrected column.
exec sys.sp_rename
    'dbo.HMCalendar.CorrectQuarter',
    'Quarter',
    'column';

-- Validate the corrected data type.
select
    column_name,
    data_type,
    character_maximum_length
from information_schema.columns
where table_schema = 'dbo'
  and table_name = 'HMCalendar'
  and column_name = 'Quarter';

-- Validate the corrected Quarter values.
select distinct
    Quarter
from dbo.HMCalendar
order by
    Quarter;

-- Return any invalid or missing Quarter values.
select
    Date,
    Year,
    MonthNo,
    Quarter
from dbo.HMCalendar
where Quarter is null
   or Quarter not in
      (
          'Q1',
          'Q2',
          'Q3',
          'Q4'
      );


/*==============================================================
  4. Standardize Country Names
  --------------------------------------------------------------
  Compare country names in HMCustomers and HMStores with the
  reference table and standardize non-matching values.
==============================================================*/

-- Identify country names that do not match the reference table.
;with AllCountries as
(
    select distinct
        Country as SourceCountry
    from dbo.HMCustomers

    union

    select distinct
        CountryName as SourceCountry
    from dbo.HMStores
)
select
    ac.SourceCountry,
    rc.Country as StandardCountry
from AllCountries as ac
left join dbo.[Countries by Continents] as rc
    on trim(ac.SourceCountry) = trim(rc.Country)
where rc.Country is null
order by
    ac.SourceCountry;

/*
Initial Findings:

Holland      → Netherlands
NewZealand   → New Zealand
SouthAfrica  → South Africa
SouthKorea   → South Korea
UAE          → United Arab Emirates
UK           → United Kingdom
US           → United States
*/

-- Standardize country names in HMCustomers.
update dbo.HMCustomers
set Country =
    case trim(Country)
        when 'Holland' then 'Netherlands'
        when 'NewZealand' then 'New Zealand'
        when 'SouthAfrica' then 'South Africa'
        when 'SouthKorea' then 'South Korea'
        when 'UAE' then 'United Arab Emirates'
        when 'UK' then 'United Kingdom'
        when 'US' then 'United States'
        else trim(Country)
    end
where trim(Country) in
(
    'Holland',
    'NewZealand',
    'SouthAfrica',
    'SouthKorea',
    'UAE',
    'UK',
    'US'
);

-- Standardize country names in HMStores.
update dbo.HMStores
set CountryName =
    case trim(CountryName)
        when 'Holland' then 'Netherlands'
        when 'NewZealand' then 'New Zealand'
        when 'SouthAfrica' then 'South Africa'
        when 'SouthKorea' then 'South Korea'
        when 'UAE' then 'United Arab Emirates'
        when 'UK' then 'United Kingdom'
        when 'US' then 'United States'
        else trim(CountryName)
    end
where trim(CountryName) in
(
    'Holland',
    'NewZealand',
    'SouthAfrica',
    'SouthKorea',
    'UAE',
    'UK',
    'US'
);

-- Revalidate country names after standardization.
;with AllCountries as
(
    select distinct
        Country as SourceCountry
    from dbo.HMCustomers

    union

    select distinct
        CountryName as SourceCountry
    from dbo.HMStores
)
select
    ac.SourceCountry,
    rc.Country as StandardCountry
from AllCountries as ac
left join dbo.[Countries by Continents] as rc
    on trim(ac.SourceCountry) = trim(rc.Country)
where rc.Country is null
order by
    ac.SourceCountry;


/*==============================================================
  5. Populate Missing Continent Values in HMStores
  --------------------------------------------------------------
  Populate missing store continents by matching CountryName
  with the Countries by Continents reference table.
==============================================================*/

-- Review stores with missing or empty continent values.
select
    StoreID,
    CountryName,
    Continent
from dbo.HMStores
where Continent is null
   or trim(Continent) = '';

-- Preview the reference continent that will be assigned.
select
    s.StoreID,
    s.CountryName,
    s.Continent as CurrentContinent,
    rc.Continent as ReferenceContinent
from dbo.HMStores as s
left join dbo.[Countries by Continents] as rc
    on trim(s.CountryName) = trim(rc.Country)
where s.Continent is null
   or trim(s.Continent) = '';

-- Populate missing or empty continent values.
update s
set s.Continent = rc.Continent
from dbo.HMStores as s
inner join dbo.[Countries by Continents] as rc
    on trim(s.CountryName) = trim(rc.Country)
where s.Continent is null
   or trim(s.Continent) = '';

-- Verify that no missing or empty continent values remain.
select
    StoreID,
    CountryName,
    Continent
from dbo.HMStores
where Continent is null
   or trim(Continent) = '';

/*==============================================================
  6. Correct Misspelled Store City Name
  --------------------------------------------------------------
  The city name Brordeaux was identified during store analysis.
  The correct city name for store FR239 in France is Bordeaux.
==============================================================*/

-- Review the incorrect city name before correction.
select
    StoreID,
    CityName,
    CountryName
from dbo.HMStores
where StoreID = 'FR239';


-- Correct the misspelled city name.
update dbo.HMStores
set CityName = 'Bordeaux'
where StoreID = 'FR239'
  and trim(CityName) = 'Brordeaux';


-- Validate the corrected city name.
select
    StoreID,
    CityName,
    CountryName
from dbo.HMStores
where StoreID = 'FR239';

/*==============================================================
  7. Final Data Cleaning Validation
  --------------------------------------------------------------
  The cleaning process addressed the following issues:

  - Generic column names and an imported header row in the
    Countries by Continents reference table
  - Incorrect SortYM data type and values
  - Incorrect Quarter data type and format
  - Non-standard country names in HMCustomers and HMStores
  - Missing or empty Continent values in HMStores
  - Misspelled CityName value in HMStores

  Each cleaning step includes its own validation query.

  After completing this script, execute 02_Data_Profiling.sql
  again to confirm that no issues remain under the implemented
  profiling rules.
==============================================================*/

/*==============================================================
  End of 03_Data_Cleaning.sql
==============================================================*/

set nocount off;