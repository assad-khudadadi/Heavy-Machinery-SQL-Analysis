/*==============================================================
  Heavy Machinery Sales Analysis
  File: 04_06_Channel_Analysis.sql
  Section: Sales Channel Performance and Revenue Trends
==============================================================

Purpose:
Evaluate the performance of sales channels across the complete
analysis period and examine how channel performance changed
over time.

Analysis Scope:
- Q9: Most successful sales channel across the full period
- Q9.1: Revenue contribution and supporting channel metrics
- Q10: Most successful sales channel during the latest five
  complete years
- Q10.1: Top-performing sales channel by year

Execution Order:
Run this script after completing:
- 02_Data_Profiling.sql
- 03_Data_Cleaning.sql
- 04_01_Dataset_Exploration.sql
- 04_02_Time_Analysis.sql
- 04_03_Customer_Analysis.sql
- 04_04_Store_Analysis.sql
- 04_05_Product_Analysis.sql

Important:
- Channel success is measured primarily by total revenue.
- Total orders, quantity sold, and average revenue per order are
  used as supporting performance measures.
- TransactionDate is used to assign sales to calendar years.
- The incomplete year 2013 is excluded from complete-year
  comparisons.
- This script is read-only and does not modify source data.
==============================================================*/

set nocount on;

/*==============================================================
  Q9. Most Successful Sales Channel
  --------------------------------------------------------------
  Business Question:
  Which sales channel generated the highest total revenue during
  the complete available analysis period?

  Objective:
  Rank sales channels by total revenue and identify the most
  successful channel.

  Success Definition:
  Channel success is measured primarily by total revenue.
  Total orders and total quantity sold are included as supporting
  performance measures.
==============================================================*/

-- Calculate the total performance of each sales channel.
;with ChannelPerformance as
(
    select
        ch.ChannelKey,
        ch.Channel,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMChannel as ch
        on s.ChannelKey = ch.ChannelKey
    group by
        ch.ChannelKey,
        ch.Channel
),

-- Rank channels by total revenue.
ChannelRanking as
(
    select
        ChannelKey,
        Channel,
        TotalOrders,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            order by TotalRevenue desc
        ) as ChannelRevenueRank
    from ChannelPerformance
)

-- Return every channel ranked first in total revenue.
select
    ChannelRevenueRank,
    ChannelKey,
    Channel,
    TotalOrders,
    TotalQuantitySold,
    cast(
        TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million
from ChannelRanking
where ChannelRevenueRank = 1
order by
    ChannelKey;

/*==============================================================
  Q9 Business Insight
  --------------------------------------------------------------
  The Website channel ranked first in total revenue across the
  complete available analysis period.

  It generated 655.40 million in revenue from 80,873 distinct
  orders and 81,327 units sold.

  The difference between total orders and total quantity sold
  was relatively small. This indicates that Website transactions
  generally contained approximately one unit per order.

  This result identifies Website as the highest-revenue channel,
  but it does not show whether the channel strongly dominated
  overall company revenue.

  Revenue contribution, average revenue per order, and the
  performance of the remaining channels must also be evaluated
  before making channel-investment decisions.
==============================================================*/

/*==============================================================
  Q9.1 Revenue Contribution and Performance by Sales Channel
  --------------------------------------------------------------
  Business Question:
  How much does each sales channel contribute to total company
  revenue, and how efficiently does each channel generate revenue
  from its orders?

  Objective:
  Compare all sales channels using revenue rank, total revenue,
  revenue contribution, order volume, quantity sold, average
  revenue per order, and average units per order.
==============================================================*/

-- Calculate the total performance of each sales channel.
;with ChannelPerformance as
(
    select
        ch.ChannelKey,
        ch.Channel,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMChannel as ch
        on s.ChannelKey = ch.ChannelKey
    group by
        ch.ChannelKey,
        ch.Channel
),

-- Calculate channel rankings, contribution, and efficiency
-- measures.
ChannelMetrics as
(
    select
        ChannelKey,
        Channel,
        TotalOrders,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            order by TotalRevenue desc
        ) as ChannelRevenueRank,
        TotalRevenue * 100.0
            / nullif(sum(TotalRevenue) over (), 0)
            as RevenueContributionPercent,
        TotalRevenue * 1.0
            / nullif(TotalOrders, 0)
            as AverageRevenuePerOrder,
        TotalQuantitySold * 1.0
            / nullif(TotalOrders, 0)
            as AverageUnitsPerOrder
    from ChannelPerformance
)

-- Return the performance metrics for every sales channel.
select
    ChannelRevenueRank,
    ChannelKey,
    Channel,
    TotalOrders,
    TotalQuantitySold,
    cast(
        TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million,
    cast(
        RevenueContributionPercent
        as decimal(6, 2)
    ) as RevenueContributionPercent,
    cast(
        AverageRevenuePerOrder
        as decimal(12, 2)
    ) as AverageRevenuePerOrder,
    cast(
        AverageUnitsPerOrder
        as decimal(8, 2)
    ) as AverageUnitsPerOrder
from ChannelMetrics
order by
    ChannelRevenueRank,
    ChannelKey;

/*==============================================================
  Q9.1 Business Insight
  --------------------------------------------------------------
  Revenue was distributed very evenly across the ten sales
  channels.

  Website ranked first with 655.40 million in revenue, but its
  contribution represented only 10.09% of total company revenue.

  SocialMedia ranked second with 653.11 million and a 10.05%
  contribution, while Quality ranked third with 651.80 million
  and a 10.03% contribution.

  Brochure ranked last but still generated 642.26 million and
  contributed 9.89% of total revenue.

  The revenue difference between Website and Brochure was only
  13.14 million, or approximately 2.05% of Brochure revenue.
  Therefore, the first-place ranking does not indicate strong
  dominance by Website.

  Average revenue per order was also highly consistent across
  channels. It ranged from 8,016.67 for Brochure to 8,104.09
  for Website, a difference of only 87.42 per order.

  Average units per order remained between 1.00 and 1.01 for
  every channel. This indicates that channel revenue differences
  were not driven by substantially larger order quantities.

  Quality recorded the highest number of distinct orders at
  80,927 and the highest quantity sold at 81,457 units, despite
  ranking third in total revenue.

  Overall, no sales channel strongly dominated revenue, order
  volume, quantity sold, or average order value. The company
  therefore appears to have a highly diversified and balanced
  channel portfolio across the full analysis period.

  However, full-period totals may hide recent changes in channel
  performance. The latest complete years should be evaluated
  separately before making future channel-investment decisions.
==============================================================*/

/*==============================================================
  Q10. Most Successful Sales Channel in the Latest Five
       Complete Years
  --------------------------------------------------------------
  Business Question:
  Which sales channel generated the highest cumulative revenue
  during the latest five complete sales years?

  Objective:
  Identify the strongest recent sales channel using cumulative
  revenue across the latest five years containing sales activity
  in all 12 months.

  Success Definition:
  Channel success is measured primarily by total revenue.
==============================================================*/

-- Identify years containing sales activity in all 12 months.
;with CompleteSalesYears as
(
    select
        c.Year
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    group by
        c.Year
    having count(distinct c.MonthNo) = 12
),

-- Rank complete years from newest to oldest.
RankedCompleteYears as
(
    select
        Year,
        row_number() over
        (
            order by Year desc
        ) as CompleteYearRank
    from CompleteSalesYears
),

-- Select the latest five complete years.
RecentYears as
(
    select
        Year
    from RankedCompleteYears
    where CompleteYearRank <= 5
),

-- Identify the beginning and end of the selected period.
RecentPeriod as
(
    select
        min(Year) as PeriodStartYear,
        max(Year) as PeriodEndYear
    from RecentYears
),

-- Calculate channel performance during the selected period.
RecentChannelPerformance as
(
    select
        ch.ChannelKey,
        ch.Channel,
        rp.PeriodStartYear,
        rp.PeriodEndYear,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMChannel as ch
        on s.ChannelKey = ch.ChannelKey
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join RecentYears as ry
        on c.Year = ry.Year
    cross join RecentPeriod as rp
    group by
        ch.ChannelKey,
        ch.Channel,
        rp.PeriodStartYear,
        rp.PeriodEndYear
),

-- Rank channels by cumulative revenue during the selected period.
RecentChannelRanking as
(
    select
        ChannelKey,
        Channel,
        PeriodStartYear,
        PeriodEndYear,
        TotalOrders,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            order by TotalRevenue desc
        ) as RecentChannelRevenueRank
    from RecentChannelPerformance
)

-- Return every channel ranked first during the selected period.
select
    RecentChannelRevenueRank,
    ChannelKey,
    Channel,
    PeriodStartYear,
    PeriodEndYear,
    TotalOrders,
    TotalQuantitySold,
    cast(
        TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million
from RecentChannelRanking
where RecentChannelRevenueRank = 1
order by
    ChannelKey;

/*==============================================================
  Q10 Business Insight
  --------------------------------------------------------------
  Magazine ranked first in cumulative revenue during the latest
  five complete sales years, covering 2008 through 2012.

  During this period, Magazine generated 298.40 million in
  revenue from 36,811 distinct orders and 37,261 units sold.

  Its average annual revenue during the five-year period was
  approximately 59.68 million.

  The number of units sold was only slightly higher than the
  number of orders. This represents approximately 1.01 units per
  order and indicates that most transactions involved a single
  unit.

  Website ranked first across the complete historical period in
  Q9, while Magazine ranked first during the latest five complete
  years.

  This difference indicates that long-term channel leadership
  did not fully represent more recent performance. Channel
  effectiveness may therefore have changed over time.

  However, this cumulative five-year result does not establish
  that Magazine ranked first in every individual year. Annual
  channel rankings must be examined separately to determine
  whether its leadership was consistent or driven by particular
  years.
==============================================================*/

/*==============================================================
  Q10.1 Top-Performing Sales Channel by Year
  --------------------------------------------------------------
  Business Question:
  Which sales channel generated the highest total revenue in
  each of the latest five complete sales years?

  Objective:
  Identify the annual revenue leader and determine whether
  channel leadership remained stable or changed over time.

  Analysis Scope:
  The same five complete years selected in Q10 are used here.
==============================================================*/

-- Identify years containing sales activity in all 12 months.
;with CompleteSalesYears as
(
    select
        c.Year
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    group by
        c.Year
    having count(distinct c.MonthNo) = 12
),

-- Rank complete years from newest to oldest.
RankedCompleteYears as
(
    select
        Year,
        row_number() over
        (
            order by Year desc
        ) as CompleteYearRank
    from CompleteSalesYears
),

-- Select the latest five complete years.
RecentYears as
(
    select
        Year
    from RankedCompleteYears
    where CompleteYearRank <= 5
),

-- Calculate annual performance for each sales channel.
AnnualChannelPerformance as
(
    select
        c.Year,
        ch.ChannelKey,
        ch.Channel,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on s.TransactionDate = c.Date
    inner join dbo.HMChannel as ch
        on s.ChannelKey = ch.ChannelKey
    inner join RecentYears as ry
        on c.Year = ry.Year
    group by
        c.Year,
        ch.ChannelKey,
        ch.Channel
),

-- Rank channels separately within each year by total revenue.
AnnualChannelRanking as
(
    select
        Year,
        ChannelKey,
        Channel,
        TotalOrders,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            partition by Year
            order by TotalRevenue desc
        ) as AnnualChannelRevenueRank
    from AnnualChannelPerformance
)

-- Return every highest-revenue channel in each selected year.
select
    Year,
    AnnualChannelRevenueRank,
    ChannelKey,
    Channel,
    TotalOrders,
    TotalQuantitySold,
    cast(
        TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million,
    cast(
        TotalRevenue * 1.0
        / nullif(TotalOrders, 0)
        as decimal(12, 2)
    ) as AverageRevenuePerOrder
from AnnualChannelRanking
where AnnualChannelRevenueRank = 1
order by
    Year,
    ChannelKey;


/*==============================================================
  Q10.1 Business Insight
  --------------------------------------------------------------
  Sales channel leadership changed in every one of the latest
  five complete years from 2008 through 2012.

  OnSiteDemo ranked first in 2008 with 60.44 million in revenue.

  InternetReview ranked first in 2009 with 60.17 million, followed
  by SocialMedia in 2010 with 59.75 million.

  Website became the annual leader in 2011 with 60.05 million,
  while Magazine ranked first in 2012 with 62.21 million.

  No channel maintained the highest-revenue position for two
  consecutive years, and all five years had different annual
  leaders.

  Magazine recorded the highest winning annual revenue at
  62.21 million in 2012. It also generated the highest average
  revenue per order among the five annual leaders at 8,479.74.

  SocialMedia recorded the lowest winning annual revenue at
  59.75 million in 2010.

  The difference between the highest and lowest winning annual
  revenue was only 2.46 million. This relatively narrow range
  indicates strong competition among the sales channels.

  Magazine ranked first in cumulative revenue across the entire
  five-year period in Q10, even though it ranked first in only
  one individual year.

  Its five-year leadership was therefore not produced by repeated
  annual first-place rankings. Instead, it indicates consistently
  competitive performance across the period, combined with its
  particularly strong result in 2012.

  Overall, recent annual performance does not show a consistently
  dominant sales channel. Channel leadership was dynamic and
  shifted from year to year.
==============================================================*/

/*==============================================================
  Channel Analysis Summary
  --------------------------------------------------------------
  - Website generated the highest revenue across the complete
    historical period, with 655.40 million.

  - Website contributed only 10.09% of total company revenue,
    showing that its first-place position did not represent
    strong channel dominance.

  - Revenue contribution was highly balanced across all ten
    channels, ranging from 9.89% to 10.09%.

  - Average revenue per order was also consistent across
    channels, ranging from 8,016.67 to 8,104.09.

  - Magazine generated the highest cumulative revenue during
    the latest five complete years from 2008 through 2012, with
    298.40 million.

  - The full-period revenue leader and the recent five-year
    leader were different, indicating that channel performance
    changed over time.

  - Five different channels ranked first in the five individual
    years examined.

  - OnSiteDemo led in 2008, InternetReview in 2009, SocialMedia
    in 2010, Website in 2011, and Magazine in 2012.

  - No channel maintained the annual revenue leadership position
    for two consecutive years.

  - Magazine ranked first cumulatively during the five-year
    period despite ranking first in only one individual year.

  - Overall, the company maintained a diversified and highly
    competitive sales-channel portfolio.
==============================================================*/


/*==============================================================
  Business Recommendations
  --------------------------------------------------------------
  1. Maintain a diversified channel strategy rather than
     concentrating investment only on Website or Magazine.

  2. Examine the operational and marketing factors behind the
     strongest year of each annual leader, including campaigns,
     customer engagement, product mix, and customer segments.

  3. Investigate the factors supporting Magazine's consistent
     performance during 2008 through 2012 and determine whether
     those strengths can be applied to other channels.

  4. Continue improving Website because it remained the strongest
     channel across the complete historical period, but do not
     interpret its narrow lead as evidence of channel dominance.

  5. Monitor channel rankings annually because full-period totals
     can hide recent changes in customer behavior and channel
     effectiveness.

  6. Compare channel revenue with marketing costs, operating
     expenses, conversion rates, and profit margins before
     reallocating company resources.

  7. Evaluate customer retention and repeat-purchase behavior by
     channel to determine whether revenue performance is driven
     by sustainable customer relationships.

  8. Use revenue contribution, order volume, average order value,
     profitability, and recent performance together when making
     channel-investment decisions.
==============================================================*/


/*==============================================================
  End of 04_06_Channel_Analysis.sql
==============================================================*/

set nocount off;
