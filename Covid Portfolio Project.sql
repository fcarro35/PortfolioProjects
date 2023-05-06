--Select *
--From PortfolioProject..CovidDeaths
--Where continent is not null -- in the data source continent with null are allocated to overall continent, not individual countries 
--order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using

Select continent, Location, date, total_cases,new_cases,total_deaths,population
From PortfolioProject..CovidDeaths
order by 1,2,3

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in you country
Select continent, Location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%Arab Emirates%'
order by 1,2,3

-- Looking at total cases vs population
-- Shows what % of population got covid
Select continent, Location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
From PortfolioProject..CovidDeaths
Where location like '%Arab Emirates%'
order by 1,2,3

--Looking at countries with highest infection rate compared to Population
Select continent, Location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 as CasePercentage
From PortfolioProject..CovidDeaths
--Where location like '%Arab Emirates%'
group by continent, location, population
order by CasePercentage desc


--Looking at countries with highest death count compared to Population
Select continent, Location, population, MAX(total_deaths) AS Total_Death_Count, MAX((total_deaths/population))*100 as Death_Rate
From PortfolioProject..CovidDeaths
--Where location like '%Arab Emirates%'
Where continent is not null
group by continent, location, population
order by Total_Death_Count desc


--LET's break things down by continent
Select location, MAX(population) AS population, MAX(total_deaths) AS Total_Death_Count
From PortfolioProject..CovidDeaths
Where continent is null
group by location
order by Total_Death_Count desc


--Showing continents with highest death rate
Select location, MAX(population) AS population, MAX(total_deaths) AS Total_Death_Count, MAX((total_deaths/population))*100 as Death_Rate
From PortfolioProject..CovidDeaths
Where continent is null
group by location
order by Death_Rate desc


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
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
From PortfolioProject..CovidDeaths d
Join PortfolioProject..CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
Where d.continent is not null
order by 2,3

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
Drop Table if exists #PercentPopulationVaccinated --better add this line if we plan on doing some alterations

Create Table #PercentPopulationVaccinated (
Continent nvarchar(255),
Location nvarchar(255),
Date date,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

Insert Into #PercentPopulationVaccinated
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



-- pause 38.26