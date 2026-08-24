/*==============================================================
  Heavy Machinery Sales Analysis
  File: 04_02_Time_Analysis.sql
  Section: Revenue Trends and Time-Based Performance
==============================================================

Purpose:
Analyze revenue performance over time, identify high-revenue
periods, rank the strongest year-month combinations, and examine
which calendar months most frequently lead annual revenue.

Analysis Scope:
- Q2: High-revenue year-month periods
- Q2.1: Annual revenue trend
- Q2.2: Top five year-month combinations by revenue
- Q2.3: Most frequently highest-revenue calendar month

Execution Order:
Run this script after completing:
- 02_Data_Profiling.sql
- 03_Data_Cleaning.sql
- 04_01_Dataset_Exploration.sql

Important:
- TransactionDate is used as the primary sales date.
- Revenue is calculated from the Revenue column in HMSales.
- This script is read-only and does not modify source data.
==============================================================*/

set nocount on;

/*==============================================================
  Q2. Identify High-Revenue Year-Month Periods
  --------------------------------------------------------------
  Business Question:
  Which year-month combinations generated more than
  50 million in total revenue?

  Objective:
  Identify exceptionally high-revenue periods that may require
  further investigation.
==============================================================*/

select
    c.Year,
    c.MonthNo,
    c.MonthName,
    cast(
		sum(cast(s.Revenue as bigint)) / 1000000.0
		as decimal(12, 2)
	) as TotalRevenue_Million
from dbo.HMSales as s
inner join dbo.HMCalendar as c
    on cast(s.TransactionDate as date) = c.Date
group by
    c.Year,
    c.MonthNo,
    c.MonthName
having
    sum(cast(s.Revenue as bigint)) > 50000000
order by
    sum(cast(s.Revenue as bigint)) desc,
    c.Year,
    c.MonthNo;


/*==============================================================
  Q2 Business Insight
  --------------------------------------------------------------
  A total of 40 year-month combinations generated more than
  50 million in revenue.

  October 2007 recorded the highest monthly revenue among these
  periods at 54.56 million.

  December appeared above the 50-million threshold in seven
  different years. May and August each appeared six times,
  while March, July, and October each appeared five times.

  February, September, and November did not exceed the
  50-million threshold in any year.

  These results identify frequently strong months but do not,
  by themselves, prove a seasonal pattern. Annual month rankings
  in Q2.3 provide a more direct evaluation of recurring monthly
  performance.
==============================================================*/

/*==============================================================
  Q2.1 Annual Revenue Trend
  --------------------------------------------------------------
  Business Question:
  How did total revenue change from year to year?

  Objective:
  Calculate annual revenue and year-over-year growth for complete
  years represented by all 12 months of sales activity.
==============================================================*/

;with AnnualRevenue as
(
    select
        c.Year,
        count(distinct c.MonthNo) as MonthsWithSales,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on cast(s.TransactionDate as date) = c.Date
    group by
        c.Year
),
CompleteAnnualRevenue as
(
    select
        Year,
        TotalRevenue
    from AnnualRevenue
    where MonthsWithSales = 12
),
AnnualRevenueComparison as
(
    select
        Year,
        TotalRevenue,
        lag(TotalRevenue) over
        (
            order by Year
        ) as PreviousYearRevenue
    from CompleteAnnualRevenue
)
select
    Year,
    cast(
        TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million,
    cast(
        (TotalRevenue - PreviousYearRevenue) * 100.0
        / nullif(PreviousYearRevenue, 0)
        as decimal(8, 2)
    ) as YearOverYearChangePercent
from AnnualRevenueComparison
order by
    Year;

/*==============================================================
  Q2.1 Business Insight
  --------------------------------------------------------------
  Annual revenue remained highly stable across the 11 complete
  years from 2002 through 2012.

  Revenue ranged from 585.65 million in 2006 to 595.42 million
  in 2012, a difference of only 9.77 million, or approximately
  1.67% of the lowest annual value.

  Year-over-year changes remained between -1.16% and 1.10%.
  The largest decline occurred in 2005, while the strongest
  increase occurred in 2007.

  Overall, the dataset shows consistent annual revenue without
  a strong long-term upward or downward trend. The incomplete
  2013 period was excluded from the annual comparison.
==============================================================*/

/*==============================================================
  Q2.2 Top Five Highest-Revenue Year-Month Combinations
  --------------------------------------------------------------
  Business Question:
  Which five year-month combinations generated the highest
  total revenue across the dataset?

  Objective:
  Rank monthly revenue across all available periods and identify
  the five strongest year-month combinations.
==============================================================*/

select top (5)
    c.Year,
    c.MonthNo,
    c.MonthName,
    cast(
        sum(cast(s.Revenue as bigint)) / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million
from dbo.HMSales as s
inner join dbo.HMCalendar as c
    on cast(s.TransactionDate as date) = c.Date
group by
    c.Year,
    c.MonthNo,
    c.MonthName
order by
    sum(cast(s.Revenue as bigint)) desc,
    c.Year,
    c.MonthNo;

/*==============================================================
  Q2.2 Business Insight
  --------------------------------------------------------------
  October 2007 generated the highest monthly revenue in the
  dataset at 54.56 million.

  May appeared twice among the top five periods, in 2012 and
  2003. October also appeared twice, in 2007 and 2002.

  The year 2007 contributed two of the five highest-revenue
  periods: October ranked first and March ranked fourth.

  Revenue among the top five periods ranged from 52.31 million
  to 54.56 million, a difference of 2.25 million. This relatively
  narrow range indicates that the strongest monthly periods
  performed at broadly similar revenue levels.

  Although May and October appear more than once, five observations
  are not sufficient to establish a recurring seasonal pattern.
==============================================================*/

/*==============================================================
  Q2.3 Most Frequently Highest-Revenue Month
  --------------------------------------------------------------
  Business Question:
  Which calendar month most frequently ranked as the
  highest-revenue month of the year?

  Objective:
  Identify the highest-revenue month in each complete year and
  measure how frequently each calendar month ranked first.
==============================================================*/

;with MonthlyRevenue as
(
    select
        c.Year,
        c.MonthNo,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on cast(s.TransactionDate as date) = c.Date
    group by
        c.Year,
        c.MonthNo
),
CompleteYears as
(
    select
        Year
    from MonthlyRevenue
    group by
        Year
    having count(distinct MonthNo) = 12
),
RankedMonths as
(
    select
        mr.Year,
        mr.MonthNo,
        mr.TotalRevenue,
        dense_rank() over
        (
            partition by mr.Year
            order by mr.TotalRevenue desc
        ) as AnnualRevenueRank
    from MonthlyRevenue as mr
    inner join CompleteYears as cy
        on mr.Year = cy.Year
),
HighestRevenueMonths as
(
    select
        Year,
        MonthNo,
        TotalRevenue
    from RankedMonths
    where AnnualRevenueRank = 1
),
HighestMonthFrequency as
(
    select
        MonthNo,
        count(*) as TimesRankedFirst
    from HighestRevenueMonths
    group by
        MonthNo
)
select
    MonthNo,
    datename(
        month,
        datefromparts(2000, MonthNo, 1)
    ) as MonthName,
    TimesRankedFirst,
    dense_rank() over
    (
        order by TimesRankedFirst desc
    ) as FrequencyRank
from HighestMonthFrequency
order by
    FrequencyRank,
    MonthNo;

/*==============================================================
  Q2.3 Business Insight
  --------------------------------------------------------------
  October ranked as the highest-revenue month in three of the
  11 complete years, giving it the highest frequency rank.

  May, July, August, and December each ranked first in two
  different years and shared the second frequency rank.

  October accounted for approximately 27.27% of the annual
  first-place occurrences, while each of the other four months
  accounted for approximately 18.18%.

  The annual revenue leaders were distributed across five
  different calendar months. Therefore, October was the most
  frequent leader, but the results do not indicate one strongly
  dominant peak season.

  December exceeded the 50-million threshold most frequently
  in Q2, while October ranked first within individual years most
  frequently in Q2.3. These measures answer different questions
  and should not be interpreted as contradictory.
==============================================================*/

/*==============================================================
  Time Analysis Summary
  --------------------------------------------------------------
  - The dataset contains 40 year-month combinations with revenue
    above 50 million.

  - October 2007 generated the highest monthly revenue at
    54.56 million.

  - Annual revenue remained stable from 2002 through 2012,
    ranging from 585.65 million to 595.42 million.

  - Year-over-year revenue changes remained between -1.16%
    and 1.10%, showing no strong long-term growth or decline.

  - December exceeded the 50-million threshold most frequently,
    appearing seven times.

  - October most frequently ranked as the highest-revenue month
    within a complete year, achieving first place three times.

  - Annual first-place months were distributed across October,
    May, July, August, and December. This suggests recurring
    strong periods but not one clearly dominant peak season.

  - The incomplete 2013 period was excluded from annual and
    annual-ranking comparisons to avoid misleading conclusions.
==============================================================*/

/*==============================================================
  Business Recommendations
  --------------------------------------------------------------
  1. Investigate the business drivers behind the strongest
     periods, particularly October 2007, by analyzing product
     mix, customers, stores, channels, and order volume.

  2. Use the historically stable annual revenue range as a
     baseline for budgeting and forecasting. Growth above this
     range should not be assumed without supporting initiatives
     or evidence.

  3. Consider preparing inventory, staffing, and marketing
     activities ahead of May, July, August, October, and December,
     since these months repeatedly appeared as annual leaders.
     Validate profitability and demand before increasing resources.

  4. Examine February, September, and November more closely.
     These months never exceeded the 50-million threshold, but
     average revenue, order volume, and profit should be analyzed
     before classifying them as underperforming periods.

  5. Compare high-revenue months with profit and order volume.
     High revenue may result from a small number of expensive
     products and may not necessarily indicate higher demand or
     stronger profitability.

  6. Exclude incomplete periods from future year-over-year and
     annual-ranking reports, or label them clearly as partial-year
     results.
==============================================================*/


/*==============================================================
  End of 04_02_Time_Analysis.sql
==============================================================*/

set nocount off;