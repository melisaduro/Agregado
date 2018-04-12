use FY1617_Coverage_Union_H2

declare @provincia as varchar(256) = '%%'
declare @Road as int = 0
declare @ciudad as varchar(256)='FERNAN-NUNEZ'
declare @Report as varchar(256)='MUN'

begin
  print 'Lanza 2G: '+@ciudad
  exec sp_MDD_Coverage_2G_Create_Table_entidad 
   @provincia,@ciudad, @Road,@Report
 end

 begin
  print 'Lanza 3G: '+@ciudad
  exec sp_MDD_Coverage_3G_Create_Table_entidad 
   @provincia,@ciudad, @Road,@Report
 end

 begin
  print 'Lanza 4G: '+@ciudad
  exec sp_MDD_Coverage_4G_Create_Table_entidad 
   @provincia,@ciudad, @Road,@Report
 end