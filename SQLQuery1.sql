Select *
From Project..CovidDeaths
where continent is not NULL
Order by 3,4

Select *
From Project..CovidVaccinations
where continent is not NULL
Order by 3,4

-- select Data that we are going to be using

Select Location,date,total_cases,new_cases,total_deaths,population
From Project..covidDeaths
where continent is not NULL
order by 1,2

--Looking at Total cases vs Total Deaths

SELECT
    Location,
    Date,
    Total_Cases,
    New_Cases,
    Total_Deaths,
    (CAST(Total_Deaths AS float) / CAST(Total_Cases AS float)) * 100 AS DeathPercentage
FROM
    Project..covidDeaths
WHERE Location LIKE '%states%'
ORDER BY
    Location, Date;

-- Looking at Total Case Vs Population
-- Shows what percentage of population got Covid

SELECT
    Location,
    Date,
    Total_Cases,
    Population,
    (CAST(Total_Cases AS float) / CAST(Population AS float)) * 100 AS DeathPercentage
FROM
    Project..covidDeaths
--WHERE Location LIKE '%states%'
ORDER BY
    Location, Date;

--Looking at Countries with Highest Infection Rate Compared to Population

SELECT
    Location,
    Population,
    MAX(Total_Cases) AS HighestInfectionCount,
    (MAX(Total_Cases) / Population) * 100 AS PercentPopulationInfected
FROM
    Project..covidDeaths

--WHERE Location LIKE '%states%'
GROUP BY
    Location, Population
ORDER BY
    PercentPopulationInfected DESC

--Showing Countries with Highest Death Count per Population

SELECT
    Location,
    MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM
    Project..covidDeaths
--WHERE Location LIKE '%states%'
where continent is not NULL
GROUP BY
    Location
ORDER BY
    TotalDeathCount DESC;

--LET'S BREAK THINGS DOWN BY CONTINENT



--showing continents with the highest death count for population

SELECT
    continent,
    MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM
    Project..covidDeaths
--WHERE Location LIKE '%states%'
where continent is not NULL
GROUP BY
    continent
ORDER BY
    TotalDeathCount DESC;

--GLOBAL NUMBERS 

	SELECT
    SUM(CAST(new_cases AS int)) AS Total_Cases,
    SUM(CAST(new_deaths AS int)) AS Total_Deaths,
    (SUM(CAST(new_deaths AS int)) / NULLIF(SUM(CAST(new_cases AS int)), 0)) * 100 AS DeathPercentage
FROM
    Project..covidDeaths
--WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY
    Date
ORDER BY 1,2

---Looking at Total Population VS Vaccinations

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(ISNULL(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
    (SUM(ISNULL(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / NULLIF(dea.population, 0)) * 100 AS VaccinationPercentage
FROM
    Project..covidDeaths dea
JOIN
    Project..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    dea.location, dea.date;

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated, VaccinationPercentage)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(ISNULL(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
        (SUM(ISNULL(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / NULLIF(dea.population, 0)) * 100 AS VaccinationPercentage
    FROM
        Project..covidDeaths dea
    JOIN
        Project..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)
SELECT *, 
FROM PopvsVac;

--TEMP TABLE

-- Drop table if it exists
IF OBJECT_ID('PercentPopulationVaccinated', 'U') IS NOT NULL
    DROP TABLE PercentPopulationVaccinated;

-- Create table
CREATE TABLE PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC,
    VaccinationPercentage NUMERIC
);

-- Insert data
INSERT INTO PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(ISNULL(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
    (SUM(ISNULL(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / NULLIF(dea.population, 0)) * 100 AS VaccinationPercentage
FROM
    Project..covidDeaths dea
JOIN
    Project..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

-- Creating View to store data for later visualizations

		CREATE VIEW PercentPopulationsVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(ISNULL(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
    (SUM(ISNULL(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / NULLIF(dea.population, 0)) * 100 AS VaccinationPercentage
FROM
    Project..covidDeaths dea
JOIN
    Project..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

	Select *
	From PercentPopulationsVaccinated
