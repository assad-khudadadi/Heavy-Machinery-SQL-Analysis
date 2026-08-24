/*==============================================================
  Heavy Machinery Sales Analysis
  File: 04_04_Store_Analysis.sql
  Section: Store Revenue, Ranking, and Performance Stability
==============================================================

Purpose:
Evaluate store performance by comparing annual revenue rankings,
revenue contribution, and changes in top-performing stores across
selected years.

Analysis Scope:
- Q5: Top 10 store revenue ranks in 2006 and 2007
- Q5.1: Revenue contribution of the top 10 store ranks
- Q6: Stores appearing within the top 10 ranks in both years
- Q6.1: Changes in the top 10 store revenue ranks

Execution Order:
Run this script after completing:
- 02_Data_Profiling.sql
- 03_Data_Cleaning.sql
- 04_01_Dataset_Exploration.sql
- 04_02_Time_Analysis.sql
- 04_03_Customer_Analysis.sql

Important:
- TransactionDate is used to assign sales to calendar years.
- Store performance is measured primarily using revenue.
- The comparison focuses on 2006 and 2007.
- Stores without sales in the selected years are excluded.
- This script is read-only and does not modify source data.
==============================================================*/

set nocount on;

/*==============================================================
  Q5. Top 10 Store Revenue Ranks in 2006 and 2007
  --------------------------------------------------------------
  Business Question:
  Which stores generated the highest total revenue in 2006
  and 2007?

  Objective:
  Rank stores by annual revenue and compare the order activity,
  sales volume, and revenue of top-performing stores.
==============================================================*/

-- Calculate annual performance for each store.
;with StorePerformance as
(
    select
        c.Year,
        s.StoreID,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Qty as bigint)) as TotalQuantitySold,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on cast(s.TransactionDate as date) = c.Date
    where c.Year in (2006, 2007)
    group by
        c.Year,
        s.StoreID
),

-- Rank stores independently within each year.
StoreRevenueRanking as
(
    select
        Year,
        StoreID,
        TotalOrders,
        TotalQuantitySold,
        TotalRevenue,
        dense_rank() over
        (
            partition by Year
            order by TotalRevenue desc
        ) as StoreRevenueRank
    from StorePerformance
)

-- Return stores within the 10 highest revenue ranks of each year.
select
    srr.Year,
    srr.StoreRevenueRank,
    srr.StoreID,
    st.CityName,
    st.CountryName,
    st.Continent,
    st.StoreType,
    srr.TotalOrders,
    srr.TotalQuantitySold,
    cast(
        srr.TotalRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_Million,
    cast(
        srr.TotalRevenue * 1.0
        / nullif(srr.TotalOrders, 0)
        as decimal(12, 2)
    ) as AverageRevenuePerOrder
from StoreRevenueRanking as srr
inner join dbo.HMStores as st
    on srr.StoreID = st.StoreID
where srr.StoreRevenueRank <= 10
order by
    srr.Year,
    srr.StoreRevenueRank,
    srr.StoreID;

/*==============================================================
  Q5 Business Insight
  --------------------------------------------------------------
  In 2006, Shenzhen ranked first with 7.82 million in revenue,
  followed by Rotterdam at 7.76 million and Seoul at 7.71 million.

  Revenue among the 2006 top 10 stores was closely distributed,
  ranging from 7.51 million to 7.82 million, a difference of
  only 0.31 million.

  Shenzhen achieved the highest revenue despite recording the
  lowest order count among the 2006 top 10 stores. Its average
  revenue per order of 9,163.58 was the highest in that group,
  indicating that order value was a major performance driver.

  In 2007, Rotterdam ranked first with 9.52 million, followed by
  Basel at 9.08 million. The third-ranked store, Chelyabinsk,
  generated 7.76 million, creating a noticeable gap between the
  first two stores and the rest of the ranking.

  Rotterdam increased from 7.76 million in 2006 to 9.52 million
  in 2007, an increase of approximately 22.69%. Its average
  revenue per order also increased from 8,837.84 to 10,404.52,
  suggesting that higher order value was an important contributor
  to its revenue growth.

  Rotterdam, Seoul, Christchurch, and Kigali appeared in the
  top 10 in both years, indicating repeated high performance.

  The geographic composition changed between the two years.
  Asia contributed five stores to the 2006 top 10, while Oceania
  increased from two stores in 2006 to four stores in 2007.

  Company-owned and privately owned stores were evenly represented
  in the 2006 top 10. In 2007, privately owned stores represented
  seven of the 10 highest-ranked stores.

  These results show that store revenue should be evaluated using
  both order volume and average order value rather than order
  count alone.
==============================================================*/

/*==============================================================
  Q5.1 Revenue Contribution of the Top 10 Store Ranks
  --------------------------------------------------------------
  Business Question:
  What percentage of total annual revenue was generated by
  stores within the top 10 revenue ranks in 2006 and 2007?

  Objective:
  Measure annual revenue concentration among top-performing
  stores and compare their contribution between the two years.
==============================================================*/

-- Calculate annual revenue generated by each store.
;with StoreRevenue as
(
    select
        c.Year,
        s.StoreID,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on cast(s.TransactionDate as date) = c.Date
    where c.Year in (2006, 2007)
    group by
        c.Year,
        s.StoreID
),

-- Rank stores by revenue within each year while preserving ties.
StoreRevenueRanking as
(
    select
        Year,
        StoreID,
        TotalRevenue,
        dense_rank() over
        (
            partition by Year
            order by TotalRevenue desc
        ) as StoreRevenueRank
    from StoreRevenue
),

-- Summarize top-ranked and total annual store revenue.
AnnualStoreSummary as
(
    select
        Year,
        sum(
			case
				when StoreRevenueRank <= 10 then 1
				else 0
			end
		) as TopRankedStoresIncluded,
        sum(
            case
                when StoreRevenueRank <= 10 then TotalRevenue
                else 0
            end
        ) as TopRankedStoreRevenue,
        sum(TotalRevenue) as TotalAnnualRevenue
    from StoreRevenueRanking
    group by
        Year
)

-- Return revenue concentration metrics for each year.
select
    Year,
    TopRankedStoresIncluded,
    cast(
        TopRankedStoreRevenue / 1000000.0
        as decimal(12, 2)
    ) as TopRankedStoreRevenue_Million,
    cast(
        TotalAnnualRevenue / 1000000.0
        as decimal(12, 2)
    ) as TotalAnnualRevenue_Million,
    cast(
        TopRankedStoreRevenue * 100.0
        / nullif(TotalAnnualRevenue, 0)
        as decimal(8, 2)
    ) as TopRankedRevenueContributionPercent,
    cast(
        (TotalAnnualRevenue - TopRankedStoreRevenue) * 100.0
        / nullif(TotalAnnualRevenue, 0)
        as decimal(8, 2)
    ) as RemainingStoreRevenuePercent
from AnnualStoreSummary
order by
    Year;

/*==============================================================
  Q5.1 Business Insight
  --------------------------------------------------------------
  In 2006, the 10 highest-ranked stores generated 76.60 million,
  representing 13.08% of total annual revenue. The remaining
  stores generated 86.92% of annual revenue.

  In 2007, the 10 highest-ranked stores generated 79.47 million,
  representing 13.42% of total annual revenue. The remaining
  stores generated 86.58%.

  Combined top-ranked store revenue increased by 2.87 million,
  or approximately 3.75%, between 2006 and 2007.

  Total annual revenue increased from 585.65 million to
  592.10 million, representing approximately 1.10% growth.

  The revenue contribution of the top-ranked stores increased
  by only 0.34 percentage points, from 13.08% to 13.42%.

  In both years, approximately 87% of annual revenue was generated
  outside the top 10 store ranks. This indicates that revenue
  was broadly distributed across the store network rather than
  being highly concentrated among a few leading locations.

  The top-ranked lists contain different stores in each year.
  Therefore, the 3.75% increase in their combined revenue should
  not be interpreted as growth for a fixed group of stores.
  Q6 evaluates the stores that appeared in both annual lists.
==============================================================*/

/*==============================================================
  Q6. Stores Appearing in the Top 10 in Both Years
  --------------------------------------------------------------
  Business Question:
  Which stores appeared within the top 10 revenue ranks in both
  2006 and 2007, and how did their performance change?

  Objective:
  Identify consistently high-ranking stores and compare their
  revenue, ranking, order volume, and average order value.
==============================================================*/

-- Calculate annual store performance.
;with StorePerformance as
(
    select
        c.Year,
        s.StoreID,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on cast(s.TransactionDate as date) = c.Date
    where c.Year in (2006, 2007)
    group by
        c.Year,
        s.StoreID
),

-- Rank stores by revenue within each year.
StoreRevenueRanking as
(
    select
        Year,
        StoreID,
        TotalOrders,
        TotalRevenue,
        dense_rank() over
        (
            partition by Year
            order by TotalRevenue desc
        ) as StoreRevenueRank
    from StorePerformance
),

-- Retain stores within the top 10 revenue ranks.
TopRankedStores as
(
    select
        Year,
        StoreID,
        StoreRevenueRank,
        TotalOrders,
        TotalRevenue
    from StoreRevenueRanking
    where StoreRevenueRank <= 10
),

-- Place the performance of recurring stores side by side.
-- Join the 2006 and 2007 top-ranked lists by StoreID.
RecurringTopStores as
(
    select
        y2006.StoreID,
        y2006.StoreRevenueRank as StoreRank_2006,
        y2007.StoreRevenueRank as StoreRank_2007,
        y2006.TotalOrders as TotalOrders_2006,
        y2007.TotalOrders as TotalOrders_2007,
        y2006.TotalRevenue as TotalRevenue_2006,
        y2007.TotalRevenue as TotalRevenue_2007
    from TopRankedStores as y2006
    inner join TopRankedStores as y2007
        on y2006.StoreID = y2007.StoreID
        and y2006.Year = 2006
        and y2007.Year = 2007
)
-- Compare recurring top-ranked stores across both years.
select
    rts.StoreID,
    st.CityName,
    st.CountryName,
    st.Continent,
    st.StoreType,
    rts.StoreRank_2006,
    rts.StoreRank_2007,
    rts.StoreRank_2006 - rts.StoreRank_2007
        as RankImprovement,
    rts.TotalOrders_2006,
    rts.TotalOrders_2007,
    rts.TotalOrders_2007 - rts.TotalOrders_2006
        as OrderChange,
    cast(
        rts.TotalRevenue_2006 / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_2006_Million,
    cast(
        rts.TotalRevenue_2007 / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_2007_Million,
    cast(
        (rts.TotalRevenue_2007 - rts.TotalRevenue_2006)
        / 1000000.0
        as decimal(12, 2)
    ) as RevenueChange_Million,
    cast(
        (rts.TotalRevenue_2007 - rts.TotalRevenue_2006) * 100.0
        / nullif(rts.TotalRevenue_2006, 0)
        as decimal(8, 2)
    ) as RevenueChangePercent,
    cast(
        rts.TotalRevenue_2006 * 1.0
        / nullif(rts.TotalOrders_2006, 0)
        as decimal(12, 2)
    ) as AverageRevenuePerOrder_2006,
    cast(
        rts.TotalRevenue_2007 * 1.0
        / nullif(rts.TotalOrders_2007, 0)
        as decimal(12, 2)
    ) as AverageRevenuePerOrder_2007
from RecurringTopStores as rts
inner join dbo.HMStores as st
    on rts.StoreID = st.StoreID
order by
    RevenueChangePercent desc,
    rts.StoreID;

/*==============================================================
  Q6 Business Insight
  --------------------------------------------------------------
  Four stores appeared within the top 10 revenue ranks in both
  2006 and 2007: Rotterdam, Christchurch, Kigali, and Seoul.

  Rotterdam delivered the strongest recurring-store performance.
  Its revenue increased from 7.76 million to 9.52 million,
  representing growth of 22.69%.

  Rotterdam's order count increased by 37, while its average
  revenue per order increased from 8,837.84 to 10,404.52,
  approximately 17.73% growth. Therefore, its revenue improvement
  was supported by both higher order volume and higher order value.

  Christchurch improved from ninth to eighth place despite a
  1.11% revenue decline. Its order count decreased by 55, but
  average revenue per order increased from 7,953.80 to 8,346.33.
  This demonstrates that ranking improvement does not necessarily
  indicate revenue growth because store rankings are relative.

  Kigali's revenue declined by 1.75%, and its ranking fell from
  sixth to tenth. Although its average revenue per order increased,
  its order count decreased by 47.

  Seoul's revenue declined by 1.86%, and its ranking fell from
  third to seventh. It was the only recurring store that recorded
  decreases in both order count and average revenue per order.

  Rotterdam was the only recurring top-ranked store to achieve
  revenue growth between 2006 and 2007. The other three stores
  remained in the top 10 despite modest revenue declines.
==============================================================*/

/*==============================================================
  Q6.1 Changes in the Top 10 Store List
  --------------------------------------------------------------
  Business Question:
  Which stores entered or exited the top 10 revenue ranks
  between 2006 and 2007?

  Objective:
  Identify emerging and declining stores by comparing changes
  in annual ranking, order volume, and revenue.
==============================================================*/

-- Calculate annual performance for every store.
;with StorePerformance as
(
    select
        c.Year,
        s.StoreID,
        count(distinct s.Invoice) as TotalOrders,
        sum(cast(s.Revenue as bigint)) as TotalRevenue
    from dbo.HMSales as s
    inner join dbo.HMCalendar as c
        on cast(s.TransactionDate as date) = c.Date
    where c.Year in (2006, 2007)
    group by
        c.Year,
        s.StoreID
),

-- Rank stores by annual revenue.
StoreRevenueRanking as
(
    select
        Year,
        StoreID,
        TotalOrders,
        TotalRevenue,
        dense_rank() over
        (
            partition by Year
            order by TotalRevenue desc
        ) as StoreRevenueRank
    from StorePerformance
),

-- Separate the two annual rankings.
StoreRanking2006 as
(
    select
        StoreID,
        StoreRevenueRank,
        TotalOrders,
        TotalRevenue
    from StoreRevenueRanking
    where Year = 2006
),
StoreRanking2007 as
(
    select
        StoreID,
        StoreRevenueRank,
        TotalOrders,
        TotalRevenue
    from StoreRevenueRanking
    where Year = 2007
),

-- Place 2006 and 2007 store performance side by side.
StoreComparison as
(
    select
        coalesce(y2006.StoreID, y2007.StoreID) as StoreID,
        y2006.StoreRevenueRank as StoreRank_2006,
        y2007.StoreRevenueRank as StoreRank_2007,
        y2006.TotalOrders as TotalOrders_2006,
        y2007.TotalOrders as TotalOrders_2007,
        y2006.TotalRevenue as TotalRevenue_2006,
        y2007.TotalRevenue as TotalRevenue_2007
    from StoreRanking2006 as y2006
    full outer join StoreRanking2007 as y2007
        on y2006.StoreID = y2007.StoreID
),

-- Classify stores that entered or exited the top 10 ranks.
Top10Changes as
(
    select
        StoreID,
        StoreRank_2006,
        StoreRank_2007,
        TotalOrders_2006,
        TotalOrders_2007,
        TotalRevenue_2006,
        TotalRevenue_2007,
        case
            when
                (StoreRank_2006 > 10 or StoreRank_2006 is null)
                and StoreRank_2007 <= 10
                then 'Entered Top 10'

            when
                StoreRank_2006 <= 10
                and (StoreRank_2007 > 10 or StoreRank_2007 is null)
                then 'Exited Top 10'
        end as Top10Change
    from StoreComparison
)

-- Return stores that entered or exited the top 10 ranks.
select
    tc.Top10Change,
    tc.StoreID,
    st.CityName,
    st.CountryName,
    st.Continent,
    st.StoreType,
    tc.StoreRank_2006,
    tc.StoreRank_2007,
    tc.StoreRank_2006 - tc.StoreRank_2007
        as RankImprovement,
    tc.TotalOrders_2006,
    tc.TotalOrders_2007,
    tc.TotalOrders_2007 - tc.TotalOrders_2006
        as OrderChange,
    cast(
        tc.TotalRevenue_2006 / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_2006_Million,
    cast(
        tc.TotalRevenue_2007 / 1000000.0
        as decimal(12, 2)
    ) as TotalRevenue_2007_Million,
    cast(
        (tc.TotalRevenue_2007 - tc.TotalRevenue_2006)
        / 1000000.0
        as decimal(12, 2)
    ) as RevenueChange_Million,
    cast(
        (tc.TotalRevenue_2007 - tc.TotalRevenue_2006) * 100.0
        / nullif(tc.TotalRevenue_2006, 0)
        as decimal(8, 2)
    ) as RevenueChangePercent
from Top10Changes as tc
inner join dbo.HMStores as st
    on tc.StoreID = st.StoreID
where tc.Top10Change is not null
order by
    tc.Top10Change,
    RevenueChangePercent desc,
    tc.StoreID;

/*==============================================================
  Q6.1 Business Insight
  --------------------------------------------------------------
  Six stores entered the top 10 revenue ranks in 2007, while
  six stores exited. Therefore, 60% of the 2006 top 10 store
  list was replaced in 2007.

  Basel recorded the strongest revenue growth among the new
  entrants. Its revenue increased by 22.71%, and its rank
  improved from 15th to second place. This growth occurred
  despite 10 fewer orders, suggesting a substantial increase
  in average order value.

  Chelyabinsk improved from 58th to third place following
  12.61% revenue growth and an increase of 27 orders.

  Melbourne, Wollongong, and Ulsan entered the top 10 with both
  higher revenue and increased order volume. Launceston entered
  the top 10 despite 30 fewer orders, indicating that higher
  order value supported its revenue growth.

  Three of the six new entrants were Australian stores:
  Melbourne, Wollongong, and Launceston. This supports the
  stronger Oceania representation observed in the 2007 ranking.

  Shenzhen experienced the largest decline among exiting stores.
  Revenue decreased by 15.52%, and its rank fell from first to
  77th place. Its order count decreased by only three, suggesting
  that lower average order value, rather than order volume alone,
  was the primary contributor to the revenue decline.

  Kolkata exited the top 10 despite recording eight additional
  orders. Its revenue declined by 5.87%, also suggesting a
  reduction in average order value.

  Bordeaux, Shanghai, HongKong, and Sydney exited the top 10
  following declines in both revenue and order volume.

  The large ranking changes relative to moderate revenue changes
  indicate that store revenue levels were relatively close.
  Therefore, ranking changes should always be evaluated together
  with absolute revenue, revenue growth, and order activity.
==============================================================*/

/*==============================================================
  Store Analysis Summary
  --------------------------------------------------------------
  - Shenzhen ranked first in 2006 with 7.82 million in revenue,
    while Rotterdam ranked first in 2007 with 9.52 million.

  - Revenue among the 2006 top-ranked stores was closely
    distributed, while Rotterdam and Basel created a larger
    performance gap at the top of the 2007 ranking.

  - The top 10 store ranks generated 13.08% of annual revenue
    in 2006 and 13.42% in 2007.

  - Approximately 87% of annual revenue was generated outside
    the top 10 store ranks in both years, indicating broad
    revenue distribution across the store network.

  - Four stores appeared in the top 10 in both years:
    Rotterdam, Christchurch, Kigali, and Seoul.

  - Rotterdam was the only recurring top-ranked store to achieve
    revenue growth, increasing revenue by 22.69%.

  - Christchurch improved its ranking despite a revenue decline,
    demonstrating that rank movement is relative and should not
    be evaluated independently.

  - Six stores entered and six stores exited the top 10 in 2007,
    replacing 60% of the previous year's list.

  - Basel recorded the strongest revenue growth among new
    entrants, while Chelyabinsk achieved the largest positive
    ranking movement.

  - Three Australian stores entered the 2007 top 10, increasing
    Oceania's representation among top-performing locations.

  - Shenzhen experienced the largest decline, falling from first
    to 77th place following a 15.52% revenue decrease.

  - Changes in average order value were an important driver of
    store performance. Order count alone did not fully explain
    revenue or ranking changes.
==============================================================*/


/*==============================================================
  Business Recommendations
  --------------------------------------------------------------
  1. Investigate the customer mix, product mix, pricing, sales
     practices, and local market conditions that supported
     Rotterdam's revenue and average-order-value growth.

  2. Review Basel and Chelyabinsk as potential internal growth
     case studies. Determine whether their performance drivers
     can be applied to other stores.

  3. Prioritize a diagnostic review of Shenzhen. Its substantial
     revenue decline occurred with only a small decrease in order
     count, suggesting a possible shift toward lower-value orders,
     products, or customers.

  4. Review Seoul and Kigali because both remained in the top 10
     but experienced revenue declines and four-position ranking
     drops.

  5. Validate whether the increased presence of Australian stores
     represents sustained regional growth or a temporary annual
     change before allocating additional resources.

  6. Maintain support across the broader store network because
     approximately 87% of annual revenue was generated outside
     the top 10 store ranks.

  7. Evaluate stores using revenue, revenue growth, order volume,
     average order value, and profitability together. Avoid using
     ranking as the sole performance measure.

  8. Establish performance alerts for significant declines in
     revenue or average order value, especially when order volume
     remains stable.

  9. Compare company-owned and privately owned stores over
     multiple years before concluding that either store type
     consistently performs better.

  10. Extend the analysis to product, customer, channel, and
      profitability metrics to identify the business causes
      behind store-performance changes.
==============================================================*/


/*==============================================================
  End of 04_04_Store_Analysis.sql
==============================================================*/

set nocount off;