--SELECT *
--FROM PortfolioProject..CovidDeaths
--Order by 3, 4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--Order by 3, 4

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4

-- Selecting all the relevant datas 

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in India

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as 'Death%'
From PortfolioProject..CovidDeaths
Where location like 'India'
and continent is not null 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in India

Select Location, date, Population, total_cases,  (total_cases/population)*100 as '%PopulationInfected'
From PortfolioProject..CovidDeaths
Where location like 'India'
order by 1,2



-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as TotalInfected,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like 'India'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount, Max((cast(Total_deaths as int)/population))*100 as PercentPopulationDeath
From PortfolioProject..CovidDeaths
--Where location like 'India'
Where continent is not null  --This deselects Continents as Locations
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like 'India'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- Showing contintents with the highest death count per population

Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount --selecting location instead of continent to get more accurate results
From PortfolioProject..CovidDeaths
--Where location like 'India'
Where continent is null -- When continent is null, location are continents itself
Group by location 
order by TotalDeathCount desc



-- GLOBAL NUMBERS
-- Across the world statistics:
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like 'India'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations	--Using OVER() & PARTITION BY() Instead of Total_Vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as CumulativePeopleVaccinated 
--, (CumulativePeopleVaccinated/population)*100		--Gives error while accessing the newly created column; 
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CumulativePeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as CumulativePeopleVaccinated
--, (CumulativePeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (CumulativePeopleVaccinated/Population)*100 as PercentVaccinated
From PopvsVac
--Where Continent like 'Asia'
--Order by Location



-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated





-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
