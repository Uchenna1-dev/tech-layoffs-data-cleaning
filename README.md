# Tech Layoffs Data Cleaning in PostgreSQL

I cleaned a dataset of 2,361 global tech layoffs (2020 to 2023) in PostgreSQL, ready for analysis. It ended at 1,995 usable rows. Along the way I found that the missing values had come through as the word "NULL" rather than as real empty values, which quietly broke several standard cleaning queries until I converted them.

**Tools:** PostgreSQL, DBeaver

## The data

Each row is one layoff event: the company, its location, industry, how many people were let go, what share of the workforce that was, the date, the company's funding stage, its country and how much funding it had raised.

## Results

| Step | Rows |
| --- | --- |
| Raw import | 2,361 |
| Exact duplicates removed | 5 |
| After removing duplicates | 2,356 |
| Rows with no layoff figures removed | 361 |
| Final clean table | 1,995 |

## What I did

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

## What I learned

**Missing values were stored as text.** My import tool kept missing values as the four letter word "NULL". So `WHERE total_laid_off IS NULL` found nothing, and `COUNT(date)` returned 0 for rows that plainly had no date. I wrapped each conversion in `NULLIF(column, 'NULL')` to turn the text into real NULLs before changing the type.

**Check what the data actually holds before trusting a query.** `COUNT(column)` skips NULLs, `IS NULL` misses the text "NULL", and `' '` (a space) is not the same as `''` (empty). Each of these hid a problem until I checked it directly.

## How to run it

1. Create a `layoffs` schema in PostgreSQL and import `layoffs.csv` (included in this repository) into a table called `layoffs.layoffs`, with every column as text.
2. Run `01_layoffs_data_cleaning.sql` from top to bottom. The final table is `layoffs.layoffs_staging2`.

## Next

Exploratory analysis of the clean table: layoffs by year, industry and country, and which companies cut the largest share of their staff.

## Acknowledgements

Dataset adapted from a public SQL tutorial; rebuilt and extended in PostgreSQL.
