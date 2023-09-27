-- Select data that is going to be used in the project.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Deaths
ORDER BY [location], [date]

-- Total Cases vs Total Death. Likelyhood of dying per country.
SELECT location, date, total_cases, total_deaths , CAST(total_deaths AS float) / CAST(total_cases AS float) * 100 AS DeathPercentage
FROM Covid_Deaths
WHERE [location] LIKE 'United States'
ORDER BY 1,2 DESC;

-- Total Cases vs Population. Percentage of population got Covid 19.
SELECT location, date, total_cases, population , CAST(total_cases AS float) / CAST(population AS float) * 100 AS PercPopulationInfected
FROM Covid_Deaths
ORDER BY 1,2 DESC;

-- Countries with highest infection rate vs Population.
SELECT 
    location, 
    population, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX(CAST(total_cases AS float) / CAST(population AS float)) * 100 AS PercPopulationInfected
FROM Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY [location], population
ORDER BY 4 DESC;

-- Countries with the highest death count vs population.
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY [location]
ORDER BY 2 DESC;

-- Continents with the highest death count vs population.
SELECT [location], MAX(total_deaths) AS TotalDeathCount
FROM Covid_Deaths
WHERE continent IS NULL
GROUP BY [location]
ORDER BY 2 DESC;

-- Global numbers.
SELECT 
    SUM(new_cases) AS TotalNewCases, 
    SUM(new_deaths) AS TotalNewDeaths, 
    CAST(SUM(new_deaths) AS float) / CAST(NULLIF(SUM(new_cases),0) AS float) * 100 AS DeathPercentage
FROM Covid_Deaths
WHERE [continent] IS NOT NULL
ORDER BY 1;

-- Total Population vs New Vaccinations Accumulation. 
SELECT 
    d.continent, 
    d.[location], 
    d.[date], 
    d.population, 
    v.new_vaccinations,
    SUM(CONVERT(bigint, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM Covid_Deaths d 
JOIN Covid_Vaccines v 
    ON d.[location] = v.[location] AND d.[date] = v.[date]
WHERE d.continent IS NOT NULL
ORDER BY 2, 3;

-- 1 CTE 
WITH PopvsNewVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS (
    SELECT 
        d.continent, 
        d.[location], 
        d.[date], 
        d.population, 
        v.new_vaccinations,
        SUM(CONVERT(bigint, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
    FROM Covid_Deaths d 
    JOIN Covid_Vaccines v 
        ON d.[location] = v.[location] AND d.[date] = v.[date]
    WHERE d.continent IS NOT NULL
    --ORDER BY 2, 3
)

SELECT *, (CAST(RollingPeopleVaccinated AS float)/ CAST(population AS float)) * 100
FROM PopvsNewVac

-- 2 Verifying the last ouput with a Temp Table.
DROP TABLE IF EXISTS #PercentPopVacc
CREATE TABLE #PercentPopVacc
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopVacc
SELECT 
    d.continent, 
    d.[location], 
    d.[date], 
    d.population, 
    v.new_vaccinations,
    SUM(CONVERT(bigint, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM Covid_Deaths d 
JOIN Covid_Vaccines v 
    ON d.[location] = v.[location] AND d.[date] = v.[date]
WHERE d.continent IS NOT NULL
ORDER BY 2, 3;

SELECT *, (CAST(RollingPeopleVaccinated AS float)/ CAST(population AS float)) * 100
FROM #PercentPopVacc

-- VIEW 1 
CREATE VIEW RollingPeopleVacc AS
SELECT 
    d.continent, 
    d.[location], 
    d.[date], 
    d.population, 
    v.new_vaccinations,
    SUM(CONVERT(bigint, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM Covid_Deaths d 
JOIN Covid_Vaccines v 
    ON d.[location] = v.[location] AND d.[date] = v.[date]
WHERE d.continent IS NOT NULL
--ORDER BY 2, 3;