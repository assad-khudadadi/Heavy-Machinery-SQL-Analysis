
/*==============================================================
 Heavy Machinery Sales Analysis - Data Profiling
==============================================================

Purpose:
Identify potential data-quality issues before data cleaning
and business analysis.

Profiling Checks:
1. NULL values
2. Empty strings
3. Leading and trailing spaces
4. Duplicate business keys
5. Numeric validation
6. Date validation

Execution Note:
This script was initially executed on the raw imported dataset
to identify data-quality issues.

After completing the data-cleaning process, the same profiling
checks were executed again to confirm that the identified issues
had been resolved.

An empty issue report after data cleaning indicates that the
corresponding validation check passed.

Important:
This script performs read-only validation and does not modify
the source data.
==============================================================*/

set nocount on;

/*==============================================================
  1. NULL Value Check
  --------------------------------------------------------------
  Check all columns dynamically and return only columns
  containing NULL values.
==============================================================*/

drop table if exists #NullReport;

create table #NullReport
(
    TableName  sysname,
    ColumnName sysname,
    NullCount  bigint
);

declare @NullSQL nvarchar(max) = N'';

select
    @NullSQL = @NullSQL + '
insert into #NullReport
select
    ''' + s.name + '.' + t.name + ''',
    ''' + c.name + ''',
    count(*)
from ' + quotename(s.name) + '.' + quotename(t.name) + '
where ' + quotename(c.name) + ' is null
having count(*) > 0;
'
from sys.tables as t
inner join sys.schemas as s
    on t.schema_id = s.schema_id
inner join sys.columns as c
    on t.object_id = c.object_id;

exec sys.sp_executesql @NullSQL;

select
    TableName,
    ColumnName,
    NullCount
from #NullReport
order by
    NullCount desc,
    TableName,
    ColumnName;

/*==============================================================
  2. Empty String Check
  --------------------------------------------------------------
  Check all text columns dynamically and return only columns
  containing empty-string values.
==============================================================*/

drop table if exists #EmptyStringReport;

create table #EmptyStringReport
(
    TableName  sysname,
    ColumnName sysname,
    EmptyCount bigint
);

declare @EmptySQL nvarchar(max) = N'';

select
    @EmptySQL = @EmptySQL + '
insert into #EmptyStringReport
select
    ''' + s.name + '.' + t.name + ''',
    ''' + c.name + ''',
    count(*)
from ' + quotename(s.name) + '.' + quotename(t.name) + '
where ' + quotename(c.name) + ' = ''''
having count(*) > 0;
'
from sys.tables as t
inner join sys.schemas as s
    on t.schema_id = s.schema_id
inner join sys.columns as c
    on t.object_id = c.object_id
inner join sys.types as ty
    on c.user_type_id = ty.user_type_id
where ty.name in
(
    'varchar',
    'nvarchar',
    'char',
    'nchar'
);

exec sys.sp_executesql @EmptySQL;

select
    TableName,
    ColumnName,
    EmptyCount
from #EmptyStringReport
order by
    EmptyCount desc,
    TableName,
    ColumnName;

/*==============================================================
  3. Leading and Trailing Spaces Check
  --------------------------------------------------------------
  Check all text columns dynamically and return only columns
  containing leading or trailing spaces.
==============================================================*/

drop table if exists #ExtraSpacesReport;

create table #ExtraSpacesReport
(
    TableName      sysname,
    ColumnName     sysname,
    ExtraSpaceCount bigint
);

declare @SpaceSQL nvarchar(max) = N'';

select
    @SpaceSQL = @SpaceSQL + '
insert into #ExtraSpacesReport
select
    ''' + s.name + '.' + t.name + ''',
    ''' + c.name + ''',
    count(*)
from ' + quotename(s.name) + '.' + quotename(t.name) + '
where ' + quotename(c.name) + ' <> trim(' + quotename(c.name) + ')
having count(*) > 0;
'
from sys.tables as t
inner join sys.schemas as s
    on t.schema_id = s.schema_id
inner join sys.columns as c
    on t.object_id = c.object_id
inner join sys.types as ty
    on c.user_type_id = ty.user_type_id
where ty.name in
(
    'varchar',
    'nvarchar',
    'char',
    'nchar'
);

exec sys.sp_executesql @SpaceSQL;

select
    TableName,
    ColumnName,
    ExtraSpaceCount
from #ExtraSpacesReport
order by
    ExtraSpaceCount desc,
    TableName,
    ColumnName;


/*==============================================================
  4. Duplicate Candidate-Key Check
  --------------------------------------------------------------
  Check the validated candidate key of each dimension and
  reference table for duplicate values.

  The source tables were imported without physical primary key
  constraints. Therefore, candidate keys are defined manually.
==============================================================*/

drop table if exists #KeyList;
drop table if exists #DuplicateReport;

create table #KeyList
(
    TableName sysname,
    KeyColumn sysname
);

insert into #KeyList
(
    TableName,
    KeyColumn
)
values
    ('HMCustomers', 'CustomerKey'),
    ('HMProducts', 'ProductKey'),
    ('HMProductCategory', 'CategoryKey'),
    ('HMProductSubCategory', 'SubCategoryKey'),
    ('HMChannel', 'ChannelKey'),
    ('HMStores', 'StoreID'),
    ('HMCalendar', 'Date'),
    ('Countries by continents', 'Country');

create table #DuplicateReport
(
    TableName      sysname,
    KeyColumn      sysname,
    DuplicateValue nvarchar(255),
    DuplicateCount bigint
);

declare @DuplicateSQL nvarchar(max) = N'';

select
    @DuplicateSQL = @DuplicateSQL + '
insert into #DuplicateReport
select
    ''dbo.' + kl.TableName + ''',
    ''' + kl.KeyColumn + ''',
    cast(' + quotename(kl.KeyColumn) + ' as nvarchar(255)),
    count(*)
from dbo.' + quotename(kl.TableName) + '
group by ' + quotename(kl.KeyColumn) + '
having count(*) > 1;
'
from #KeyList as kl;

exec sys.sp_executesql @DuplicateSQL;

select
    TableName,
    KeyColumn,
    DuplicateValue,
    DuplicateCount
from #DuplicateReport
order by
    TableName,
    KeyColumn,
    DuplicateCount desc;

/*==============================================================
  4.1 HMSales Composite Candidate-Key Check
  --------------------------------------------------------------
  Validate whether the combination of Invoice and ProductKey
  uniquely identifies each sales line in the available dataset.
==============================================================*/

select
    Invoice,
    ProductKey,
    count(*) as DuplicateCount
from dbo.HMSales
group by
    Invoice,
    ProductKey
having count(*) > 1
order by
    DuplicateCount desc,
    Invoice,
    ProductKey;


/*==============================================================
  5. Numeric Validation for HMSales
  --------------------------------------------------------------
  Validate the following business rules:

  - Quantity must be greater than zero.
  - Price must be greater than zero.
  - Cost cannot be negative.
==============================================================*/

drop table if exists #NumericValidationReport;

create table #NumericValidationReport
(
    TableName  sysname,
    ColumnName sysname,
    CheckType  nvarchar(100),
    IssueCount bigint
);

insert into #NumericValidationReport
select
    'dbo.HMSales',
    'Qty',
    'Qty <= 0',
    count(*)
from dbo.HMSales
where Qty <= 0
having count(*) > 0;

insert into #NumericValidationReport
select
    'dbo.HMSales',
    'Price',
    'Price <= 0',
    count(*)
from dbo.HMSales
where Price <= 0
having count(*) > 0;

insert into #NumericValidationReport
select
    'dbo.HMSales',
    'Cost',
    'Cost < 0',
    count(*)
from dbo.HMSales
where Cost < 0
having count(*) > 0;

select
    TableName,
    ColumnName,
    CheckType,
    IssueCount
from #NumericValidationReport
order by
    IssueCount desc,
    ColumnName;


/*==============================================================
  6. Date Validation for HMSales
  --------------------------------------------------------------
  Validate that DeliveryDate is not earlier than
  TransactionDate.
==============================================================*/

drop table if exists #DateValidationReport;

create table #DateValidationReport
(
    TableName  sysname,
    ColumnName sysname,
    CheckType  nvarchar(100),
    IssueCount bigint
);

insert into #DateValidationReport
select
    'dbo.HMSales',
    'TransactionDate / DeliveryDate',
    'DeliveryDate < TransactionDate',
    count(*)
from dbo.HMSales
where DeliveryDate < TransactionDate
having count(*) > 0;

select
    TableName,
    ColumnName,
    CheckType,
    IssueCount
from #DateValidationReport
order by
    IssueCount desc;

/*==============================================================
  7. Final Data Profiling Summary
  --------------------------------------------------------------
  Summarize all profiling checks and display a Passed or Failed
  status for each validation category.

  An IssueCount of zero indicates that the check passed.
==============================================================*/

drop table if exists #DataProfilingSummary;

create table #DataProfilingSummary
(
    CheckType  nvarchar(100),
    IssueCount bigint,
    Status     varchar(10)
);

insert into #DataProfilingSummary
(
    CheckType,
    IssueCount,
    Status
)
select
    'NULL Values',
    coalesce
    (
        (select sum(NullCount) from #NullReport),
        0
    ),
    case
        when coalesce
        (
            (select sum(NullCount) from #NullReport),
            0
        ) = 0 then 'Passed'
        else 'Failed'
    end

union all

select
    'Empty Strings',
    coalesce
    (
        (select sum(EmptyCount) from #EmptyStringReport),
        0
    ),
    case
        when coalesce
        (
            (select sum(EmptyCount) from #EmptyStringReport),
            0
        ) = 0 then 'Passed'
        else 'Failed'
    end

union all

select
    'Leading or Trailing Spaces',
    coalesce
    (
        (select sum(ExtraSpaceCount) from #ExtraSpacesReport),
        0
    ),
    case
        when coalesce
        (
            (select sum(ExtraSpaceCount) from #ExtraSpacesReport),
            0
        ) = 0 then 'Passed'
        else 'Failed'
    end

union all

select
    'Duplicate Candidate Keys',
    coalesce
    (
        (select sum(DuplicateCount) from #DuplicateReport),
        0
    ),
    case
        when coalesce
        (
            (select sum(DuplicateCount) from #DuplicateReport),
            0
        ) = 0 then 'Passed'
        else 'Failed'
    end

union all

select
    'HMSales Composite Candidate Key',
    (
        select count(*)
        from
        (
            select
                Invoice,
                ProductKey
            from dbo.HMSales
            group by
                Invoice,
                ProductKey
            having count(*) > 1
        ) as DuplicateSalesKeys
    ),
    case
        when
        (
            select count(*)
            from
            (
                select
                    Invoice,
                    ProductKey
                from dbo.HMSales
                group by
                    Invoice,
                    ProductKey
                having count(*) > 1
            ) as DuplicateSalesKeys
        ) = 0 then 'Passed'
        else 'Failed'
    end

union all

select
    'Numeric Validation',
    coalesce
    (
        (select sum(IssueCount) from #NumericValidationReport),
        0
    ),
    case
        when coalesce
        (
            (select sum(IssueCount) from #NumericValidationReport),
            0
        ) = 0 then 'Passed'
        else 'Failed'
    end

union all

select
    'Date Validation',
    coalesce
    (
        (select sum(IssueCount) from #DateValidationReport),
        0
    ),
    case
        when coalesce
        (
            (select sum(IssueCount) from #DateValidationReport),
            0
        ) = 0 then 'Passed'
        else 'Failed'
    end;

select
    CheckType,
    IssueCount,
    Status
from #DataProfilingSummary
order by
    case Status
        when 'Failed' then 1
        when 'Passed' then 2
    end,
    CheckType;


/*==============================================================
  Data Profiling Result Interpretation
  --------------------------------------------------------------
  This profiling script was executed first on the raw imported
  dataset to identify data-quality issues.

  The initial profiling identified issues including:

  - NULL values in selected columns
  - Missing continent values in HMStores
  - Incorrectly imported HMCalendar columns
  - Non-standard country names
  - An incorrectly imported header row in the geographic
    reference table

  After completing 03_Data_Cleaning.sql, this profiling script
  was executed again to validate the cleaned dataset.

  In the individual validation sections, an empty result set
  indicates that no records violated the corresponding rule.

  In the final summary:

  - Passed indicates that no issue was detected.
  - Failed indicates that one or more records require review.
  - IssueCount shows the number of detected violations.

  The profiling checks validate the implemented rules but do not
  guarantee that the dataset is free from every possible business
  or data-quality issue.

  Additional validation may be required if new business rules,
  source tables, or data fields are introduced.
==============================================================*/


/*==============================================================
  End of 02_Data_Profiling.sql
==============================================================*/

set nocount off;

