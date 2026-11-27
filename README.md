# Tech Layoffs: Data Cleaning and Analysis in PostgreSQL

I cleaned a dataset of 2,361 global tech layoffs (2020 to 2023) in PostgreSQL and then explored it to see when, where and in which industries the cuts happened. Cleaning left 1,995 usable rows. Along the way I found that the missing values had come through as the word "NULL" rather than as real empty values, which quietly broke several standard cleaning queries until I converted them.

**Tools:** PostgreSQL, DBeaver

## The data

Each row is one layoff event: the company, its location, industry, how many people were let go, what share of the workforce that was, the date, the company's funding stage, its country and how much funding it had raised.

The dataset only covers technology companies. So an industry such as Food or Transportation means tech firms in that sector, like delivery apps or ride hailing, not restaurants or bus companies. It doesn't show layoffs across the whole economy.

## Cleaning results

| Step | Rows |
| --- | --- |
| Raw import | 2,361 |
| Exact duplicates removed | 5 |
| After removing duplicates | 2,356 |
| Rows with no layoff figures removed | 361 |
| Final clean table | 1,995 |

## How I cleaned it

**1. Worked on a copy.** All cleaning happens in staging tables, so the original import is never changed.

**2. Removed duplicates.** I numbered rows with `ROW_NUMBER()` partitioned by every column, so only rows identical in all nine columns count as duplicates. I checked the 5 extra copies before deleting them. PostgreSQL can't delete from a CTE, so I stored the row numbers in a second staging table first.

**3. Standardised the text.**
* Trimmed stray spaces from company names.
* Merged "Crypto", "Crypto Currency" and "CryptoCurrency" into one industry.
* Merged "United States" and "United States." (with a full stop) into one country.

**4. Fixed the types.** Every column arrived as text, so I converted them:

| Column | New type | Note |
| --- | --- | --- |
| `date` | date | Parsed month first (`MM/DD/YYYY`); 1 missing date stored as the text "NULL" |
| `total_laid_off` | integer | |
| `percentage_laid_off` | numeric | Holds fractions such as 0.15 |
| `funds_raised_millions` | numeric | Integer failed: 45 values have decimals |

**5. Handled missing values.** Where a company had a blank industry on one row but a known industry on another, I filled it in from the matching row. Bally's has no other row to copy from, so its industry stays empty. I then removed the 361 rows that had neither a layoff count nor a percentage, since they can't support any analysis of layoff size.

## Findings

The data runs from 11 March 2020 to 6 March 2023. Totals only count rows with a headcount, so companies that reported a percentage but no number aren't included in the sums.

**Layoffs came in two waves.** The first hit at the start of the pandemic, then 2021 went quiet. The second, much bigger wave began in late 2022.

| Year | People laid off |
| --- | --- |
| 2020 | 80,998 |
| 2021 | 15,823 |
| 2022 | 160,661 |
| 2023 (January to early March only) | 125,677 |

Another 500 layoffs have no date. A rolling monthly total brings the dated figures to 383,159.

**2023 was on course to be the worst year.** January 2023 alone saw 84,714 layoffs, more than the whole of 2020. The five worst months:

| Month | People laid off |
| --- | --- |
| January 2023 | 84,714 |
| November 2022 | 53,451 |
| February 2023 | 36,493 |
| April 2020 | 26,710 |
| May 2020 | 25,804 |

**The biggest names made the biggest cuts.** Amazon laid off 18,150 people over the period and Google 12,000. Meta had the most of any company in 2022, with 11,000.

**The United States accounts for about two thirds of all layoffs**, with 256,559. Consumer was the hardest hit industry, at 45,182.

**Funding didn't guarantee survival.** Some companies laid off 100% of their staff, meaning they shut down. Britishvolt had raised $2.4bn and still closed.

## What I learned

**Missing values were stored as text.** My import tool kept missing values as the four letter word "NULL". So `WHERE total_laid_off IS NULL` found nothing, and `COUNT(date)` returned 0 for rows that plainly had no date. I wrapped each conversion in `NULLIF(column, 'NULL')` to turn the text into real NULLs before changing the type.

**Check what the data actually holds before trusting a query.** `COUNT(column)` skips NULLs, `IS NULL` misses the text "NULL", and `' '` (a space) is not the same as `''` (empty). Each of these hid a problem until I checked it directly.

**"Top five in each year" needs three stages.** First sum the layoffs per company per year, then rank them with `DENSE_RANK()` partitioned by year, then filter to ranks 1 to 5. The filter needs its own step because `WHERE` runs before the ranking exists.

## How to run it

1. Create a `layoffs` schema in PostgreSQL and import `layoffs.csv` (included in this repository) into a table called `layoffs.layoffs`, with every column as text.
2. Run `01_layoffs_data_cleaning.sql` from top to bottom. The final table is `layoffs.layoffs_staging2`.
3. Run the queries in `02_layoffs_eda.sql` one at a time to reproduce the findings.

## Acknowledgements

Dataset adapted from a public SQL tutorial; rebuilt and extended in PostgreSQL.
