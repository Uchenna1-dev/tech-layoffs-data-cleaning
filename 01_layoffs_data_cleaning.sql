-- Layoffs data cleaning (PostgreSQL)
-- Steps:
-- 1. Remove duplicates
-- 2. Standardise the data
-- 3. Deal with NULL and blank values
-- 4. Remove unnecessary rows and columns

-- Work on a copy so the original table stays untouched
drop table if exists layoffs.layoffs_staging;
create table layoffs.layoffs_staging as (
select * from layoffs.layoffs);

select count(*) from layoffs.layoffs_staging;

-- 1. Remove duplicates

-- Find duplicates: a row number above 1 means an exact copy of an earlier row
with duplicate_cte as (
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off,
date, stage, country, funds_raised_millions) as row_num
from layoffs.layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;

-- A CTE can't be deleted from, so store the row numbers in a second staging table
drop table if exists layoffs.layoffs_staging2;
create table layoffs.layoffs_staging2 as (
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off,
date, stage, country, funds_raised_millions) as row_num
from layoffs.layoffs_staging);

-- Check what will be deleted first
select *
from layoffs.layoffs_staging2
where row_num > 1;

-- Delete the extra copies, keeping the first of each
delete
from layoffs.layoffs_staging2
where row_num > 1;

select count(*) from layoffs.layoffs_staging2; -- rows left after removing duplicates

-- 2. Standardise the data

-- Remove spaces at the start and end of company names
select company, trim(company)
from layoffs.layoffs_staging2;

update layoffs.layoffs_staging2
set company = trim(company);

-- Crypto appears under several spellings; make them one
select distinct industry
from layoffs.layoffs_staging2
where industry like '%Crypto%';

update layoffs.layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

-- United States appears with and without a full stop
select distinct country
from layoffs.layoffs_staging2
where country like '%United States%';

update layoffs.layoffs_staging2
set country = 'United States'
where country like 'United States%';

select distinct country
from layoffs.layoffs_staging2
order by country;

-- Dates: missing dates were imported as the text 'NULL', so count them first
select count(*)
from layoffs.layoffs_staging2
where date = 'Null';


-- Convert the date column from text to a real date, month first
alter table layoffs.layoffs_staging2
alter column date type date
using to_date(nullif(date, 'NULL'), 'MM/DD/YYYY');


-- 3. NULL and blank values

-- Number columns: convert from text, turning the text 'NULL' into real NULLs
-- funds_raised_millions uses numeric because some values have decimals
alter table layoffs.layoffs_staging2
alter column total_laid_off type integer
using cast(nullif(total_laid_off, 'NULL') as integer),
alter column percentage_laid_off type numeric
using cast(nullif(percentage_laid_off, 'NULL') as numeric),
alter column funds_raised_millions type numeric
using cast(nullif(funds_raised_millions, 'NULL') as numeric);

-- Industry: turn the text 'NULL' and blanks into real NULLs
update layoffs.layoffs_staging2
set industry = null
where industry = 'NULL' or industry = '';

select *
from layoffs.layoffs_staging2
where industry is null;

-- Fill a missing industry from another row of the same company
select t1.company, t1.industry, t2.industry
from layoffs.layoffs_staging2 t1
join layoffs.layoffs_staging2 t2
    on t1.company = t2.company and t1.location = t2.location
where t1.industry is null and t2.industry is not null;

update layoffs.layoffs_staging2 t1
set industry = t2.industry
from layoffs.layoffs_staging2 t2
where t1.company = t2.company
and t1.industry is null
and t2.industry is not null;

-- Bally's has no other row to copy from, so it stays NULL
select *
from layoffs.layoffs_staging2
where industry is null;


-- 4. Remove unnecessary rows and columns

-- Rows with neither a number nor a percentage laid off can't be used for analysis
select count(*)
from layoffs.layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

delete
from layoffs.layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- row_num was only needed to find duplicates
alter table layoffs.layoffs_staging2
drop column row_num;

-- Final check
select count(*) from layoffs.layoffs_staging2;

select *
from layoffs.layoffs_staging2;

select count(*)
from layoffs.layoffs_staging
where funds_raised_millions like '%.%';