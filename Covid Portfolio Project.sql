--Select columns that we are going to be using
SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2, 3

--Compare Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT continent, Location, date, population, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Arab Emirates%'
ORDER BY 1, 2, 3

--Compare total cases vs population
--Shows what % of population got covid
SELECT continent, Location, date, population, total_cases, (total_cases / population) * 100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Arab Emirates%'
ORDER BY 1, 2, 3

--Find countries with highest infection rate compared to population
SELECT continent, Location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases / population)) * 100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
--Where location like '%Arab Emirates%'
GROUP BY continent, location, population
ORDER BY CasePercentage DESC

--Find countries with highest death count compared to population
SELECT continent, Location, population, MAX(total_deaths) AS Total_Death_Count, MAX((total_deaths / population)) * 100 AS Death_Rate
FROM PortfolioProject..CovidDeaths
--Where location like '%Arab Emirates%'
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY Total_Death_Count DESC

--Break down data by continent
SELECT location, MAX(population) AS population, MAX(total_deaths) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

--Show continents with highest death rate
SELECT location, MAX(population) AS population, MAX(total_deaths) AS Total_Death_Count, MAX((total_deaths / population)) * 100 AS Death_Rate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Death_Rate DESC


--GLOBAL NUMBERS BY DAY
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS Death_Percentage --NULLIF function to return a NULL value if SUM(new_cases) is zero. This will prevent the divide-by-zero error and return NULL for the Death_Percentage in such cases
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL --AND new_cases > 0 
GROUP BY date 
ORDER BY 1, 2

--GLOBAL NUMBERS TOTAL
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS Death_Percentage --NULLIF function to return a NULL value if SUM(new_cases) is zero. This will prevent the divide-by-zero error and return NULL for the Death_Percentage in such cases
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL --AND new_cases > 0 
--GROUP BY date 
--ORDER BY 1, 2


--Looking at total population vs vaccination
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2, 3


--Adding rolling count
SELECT 
  d.continent, 
  d.location, 
  d.date, 
  d.population, 
  v.new_vaccinations, 
  SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.date, d.location) AS rolling_people_vaccinated
FROM 
  PortfolioProject..CovidDeaths d
  JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location AND d.date = v.date
WHERE 
  d.continent IS NOT NULL
ORDER BY 
  d.location, 
  d.date

--Adding % ppl vaccinated to date using CTE
With Pop_vs_Vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) as (
SELECT 
  d.continent, 
  d.location, 
  d.date, 
  d.population, 
  v.new_vaccinations, 
  SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.date, d.location) AS rolling_people_vaccinated
FROM 
  PortfolioProject..CovidDeaths d
  JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location AND d.date = v.date
WHERE 
  d.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *,  (rolling_people_vaccinated/population)*100 AS vaccination_percentage
From Pop_vs_Vac

--Adding % ppl vaccinated to date using a TEMP TABLE instead
DROP TABLE IF EXISTS #PercentPopulationVaccinated -- better add this line if we plan on doing some alterations

CREATE TABLE #PercentPopulationVaccinated (
    Continent nvarchar(255),
    Location nvarchar(255),
    Date date,
    Population numeric,
    New_vaccinations numeric,
    Rolling_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
  d.continent, 
  d.location, 
  d.date, 
  d.population, 
  v.new_vaccinations, 
  SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.date, d.location) AS rolling_people_vaccinated
FROM 
  PortfolioProject..CovidDeaths d
  JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location AND d.date = v.date
WHERE 
  d.continent IS NOT NULL

SELECT *,  (rolling_people_vaccinated/population)*100 AS vaccination_percentage
From #PercentPopulationVaccinated


--Create a view to store data for later visualization
USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated AS 
SELECT 
  d.continent, 
  d.location, 
  d.date, 
  d.population, 
  v.new_vaccinations, 
  SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.date, d.location) AS rolling_people_vaccinated
FROM 
  PortfolioProject..CovidDeaths d
  JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location AND d.date = v.date
WHERE 
  d.continent IS NOT NULL
