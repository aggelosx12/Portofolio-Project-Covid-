select *
from PortofolioProjectCovid..CovidDeaths$
Where continent is not null 
order by 3,4

select *
from PortofolioProjectCovid..CovidVaccinations$
order by 3,4

--select data that we will use 

select location , date , total_cases , new_cases , total_deaths , population -- select the attributes 

from PortofolioProjectCovid..CovidDeaths$ -- from what table 

order by 1 , 2 -- specifies  that we want the result by the 1 and 2 column

-- looking for total cases  vs total deaths 

select Location , date , total_cases , total_deaths , (total_cases/total_deaths) *100 as DeathPercentage --we define the total_cases and total_deaths as DeathPercentage and we make it decimal 

from PortofolioProjectCovid..CovidDeaths$ -- from what table 

where location = 'UNITED STATES' -- WE DO THAT TO GET ONLY THE US FROM OUR TABLE

order by 1 , 2 -- specifies  that we want the result by the 1 and 2 column


--looking at total cases  vs population
-- shows what % of population  got infected  
select Location , date , total_cases , population ,  (total_cases/population) *100 as DeathPercentage --we define the total_cases and  population as DeathPercentage and we make it decimal 


from PortofolioProjectCovid..CovidDeaths$ -- from what table 

where location = 'UNITED STATES' -- WE DO THAT TO GET ONLY THE US FROM OUR TABLE

order by 1 , 2 -- specifies  that we want the result by the 1 and 2 column

-- looking at the countries with the largest infection area compared to population

select Location ,  population , MAX(total_cases) as HighInfection,  MAX((total_cases/population)) *100 as PopulationInfected 

from PortofolioProjectCovid..CovidDeaths$ -- from what table 

Group by Location , population  -- groups rows that have the same values into Location , population rows

order by PopulationInfected Desc  --Desc means from highest to lowest 

-- Showing countries with the highest death per population 
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount -- In SQL, MAX(CAST(...)) combines two functions:

from PortofolioProjectCovid..CovidDeaths$ -- from what table 

Where continent is not null 

Group by Location  -- groups rows that have the same values into Location , population rows

order by TotalDeathCount Desc --Desc means from highest to lowest 

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount -- In SQL, MAX(CAST(...)) combines two functions (MAX() returns the largest (maximum) value in a column or expression.)
--(CAST() converts a value from one data type to another.)

from PortofolioProjectCovid..CovidDeaths$ -- from what table 

Where continent is not null  -- means where continent in the table is not null 

Group by continent

order by TotalDeathCount desc

-- GLOBAL NUMBERS

-- Calculate total cases, total deaths (converting deaths to int), 
-- and the percentage of deaths relative to total cases
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage

from PortofolioProjectCovid..CovidDeaths$ -- from what table 

where continent is not null 

order by 1,2

-- ##########################################
-- Total Population vs Vaccinations
-- Goal: Show % of population that has received at least one Covid vaccine
-- We calculate cumulative vaccinated people using a window function,
-- then divide by total population to get percentage vaccinated.
-- ##########################################
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

    -- Future calculation example:
    -- (RollingPeopleVaccinated/population)*100 = % vaccinated
FROM PortofolioProjectCovid..CovidDeaths$ dea
JOIN PortofolioProjectCovid..CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL   -- Exclude summary rows like "World", "International"
ORDER BY 2, 3;  -- Order by location and date


-- ##########################################
-- Using a CTE to calculate % vaccinated
-- Purpose: First calculate rolling total in CTE, then compute % in main SELECT
-- ##########################################

WITH PopvsVac 
(
    Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated
)
AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        
        -- Rolling cumulative vaccinations 
        SUM(CONVERT(int, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) 
            AS RollingPeopleVaccinated
    from PortofolioProjectCovid..CovidDeaths$ dea
    JOIN PortofolioProjectCovid..CovidVaccinations$  vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
-- Select everything + calculate % vaccinated
SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentVaccinated
FROM PopvsVac;


-- ##########################################
-- Using a Temp Table to perform same calculation
-- Purpose: Show another method (useful for staging or debugging data)
-- ##########################################

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert cumulative vaccination data into temp table
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,

    -- Rolling cumulative vaccinations
    SUM(CONVERT(int, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) 
        AS RollingPeopleVaccinated
from PortofolioProjectCovid..CovidDeaths$ dea
JOIN PortofolioProjectCovid..CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- Final query: now calculate % vaccinated from temp table
SELECT 
    *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated;


