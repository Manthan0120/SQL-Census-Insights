Select *
From Cencus_project.dbo.Data1

Select *
From Cencus_project.dbo.Data2

--number of rows into dataset

select count(*) from Cencus_project..Data1
select count(*) from Cencus_project..Data2

--dataset for jharkhand and bihar

select * from Cencus_project..Data1 where state in ('Jharkhand', 'Bihar')

--calculate total population in dataset

select sum(Population) population from Cencus_project..Data2

--calculate average growth 

select state, avg(Growth)*100 avg_growth from Cencus_project..Data1 group by state

--calculate sex_ratio 

select state, round(avg(Sex_Ratio),0) avg_sex_ratio from Cencus_project..Data1 
group by state
order by avg_sex_ratio desc

--calculate literacy

select state, round(avg(Literacy),0) avg_literacy_ratio from Cencus_project..Data1 
group by state
having round(avg(Literacy),0)>90
order by avg_literacy_ratio desc

-- top 3 states with highest growth ratio

select top 3 state, round(avg(Growth)*100,0) avg_growth from Cencus_project..Data1 group by state order by avg_growth desc

--bottom 3 state showing lowest sex ratio

select top 3 state,round(avg(sex_ratio),0) avg_growth from Cencus_project..Data1 group by state order by avg_growth asc

--top and bottom 3 states in literacy state
drop table if exists #topstates
create table #topstates
( state nvarchar(255),
  topstates float
  )

insert into #topstates
select state,round(avg(Literacy),0) avg_literacy_ratio from Cencus_project..Data1
group by state
order by avg_literacy_ratio desc;

select top 3 * from #topstates order by #topstates.topstates desc

drop table if exists #bottomstates
create table #bottomstates
( state nvarchar(255),
  bottomstates float

  )

insert into #bottomstates
select state,round(avg(Literacy),0) avg_literacy_ratio from Cencus_project..Data1 
group by state order by avg_literacy_ratio desc

select top 3 * from #bottomstates order by #bottomstates.bottomstates asc

--union operator

select * from (select top 3 * from #topstates order by #topstates.topstates desc) a
union
select * from (select top 3 * from #bottomstates order by #bottomstates.bottomstates asc) b

--states starting with letter a

select distinct state from Cencus_project..Data1 where lower(state) like 'a%' or lower(state) like 'b%'

select distinct state from Cencus_project..Data1 where lower(state) like 'a%' and lower(state) like '%h'

--joining both tables 

--sex_ratio
select d.state, sum(d.males) total_males, sum(d.females) total_females from
(select c.district, c.state, round(c.population/(c.sex_ratio+1),0) males, round((c.population*c.sex_ratio)/(c.sex_ratio+1),0) females from
(select a.district, a.state, a.sex_ratio, b.population 
from Cencus_project..Data1 a 
inner join Cencus_project..Data2 b on a.district = b.district) c) d
group by d.state

--literacy_ratio
select d.state, sum(total_literates) literacy, sum(total_illiterates) illiteracy from
(select c.district, c.state, round(c.literacy_ratio*c.population,0) total_literates, round((1-c.literacy_ratio)*c.population,0) total_illiterates from
(select a.district, a.state, a.literacy/100 literacy_ratio, b.population 
from Cencus_project..Data1 a 
inner join Cencus_project..Data2 b on a.district = b.district) c) d
group by d.state

--population in previous census

select d.state, round((d.current_population-d.previous_census)/(d.previous_census) * 100,2) percentage_increase from
(select c.state, round(c.population/(1+c.growth_rate),0) previous_census, population current_population from
(select a.district, a.state, a.growth growth_rate, b.population 
from Cencus_project..Data1 a 
inner join Cencus_project..Data2 b on a.district = b.district) c) d

select round((f.current_population-f.previous_census)/(f.previous_census) * 100,2) percentage_increase from
(select sum(e.previous_census) previous_census, sum(e.current_population) current_population from
(select c.state, round(c.population/(1+c.growth_rate),0) previous_census, population current_population from
(select a.district, a.state, a.growth growth_rate, b.population 
from Cencus_project..Data1 a 
inner join Cencus_project..Data2 b on a.district = b.district) c) e) f

--population per area

select j.total_area/j.previous_census * 100, j.total_area/j.current_population * 100 from
(select q.*,r.total_area from   --to specify column name because same column name 
(select '1' as key1,n.*from
(select sum(e.previous_census) previous_census, sum(e.current_population) current_population from
(select c.state, round(c.population/(1+c.growth_rate),0) previous_census, population current_population from
(select a.district, a.state, a.growth growth_rate, b.population 
from Cencus_project..Data1 a 
inner join Cencus_project..Data2 b on a.district = b.district) c) e)n) q inner join 
(select '1' as key1,l.*from
(select sum(area_km2) total_area from Cencus_project..Data2)l) r on q.key1=r.key1) j

--window function

select a.* from 
(select district,state,literacy,rank() 
over(partition by state order by literacy desc) rank1 from Cencus_project..Data1) a
where rank1 in (1,2,3)
order by state