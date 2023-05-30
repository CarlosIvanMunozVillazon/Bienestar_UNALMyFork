/*
	Script de creación de Procedimientos almacenados y funciones. Deben ser procedimientos a resolver tareas especificas del negocio que están 
    implementando de acuerdo a los perfiles/roles. Se les debe asignar permisos de acuerdo a los roles
*/

set global log_bin_trust_function_creators = 1;

#--------------------------------------------------------------------------------------------------------------------------------------------
#                                  									Valeria
#--------------------------------------------------------------------------------------------------------------------------------------------


# 1. ------------------------------- Un usuario que necesita ver sus citas medicas proximas -------------------------------------------------
DROP PROCEDURE IF EXISTS pas_citas_agendadas;
DELIMITER $$
CREATE PROCEDURE pas_citas_agendadas(IN pacienteID INT)
	BEGIN 
		SELECT * FROM vw_citamedica_agendada WHERE paciente = pacienteID;
    END $$
DELIMITER ;


# 2. -------------------------------------- Un usuario que necesita cancelar alguna cita ----------------------------------------------------

# Verificar que la cita no sea dentro de menos de las proximas 24 horas, si es asi, enviar un error
DROP TRIGGER IF EXISTS tr_check_tiempo;
DELIMITER $$
CREATE TRIGGER tr_check_tiempo BEFORE UPDATE ON citamedica
	FOR EACH ROW
    BEGIN
		DECLARE msg VARCHAR(200);
		IF DATEDIFF(OLD.citFecha, CURRENT_DATE()) < 1 THEN
			SET msg = CONCAT('La cita es dentro de las proximas 24 horas, no se puede');
            SIGNAL sqlstate '15000' SET message_text = msg;
        END IF;
    END $$
DELIMITER ;

# Eliminar la cita medica (en otras palabras, poner como NULL el paciente de dicha cita)
DROP PROCEDURE IF EXISTS pas_delete_cita_medica;
DELIMITER $$
CREATE PROCEDURE pas_delete_cita_medica(IN usuarioID INT, IN fechaCita DATETIME, IN especialidadCita VARCHAR(45))
	BEGIN
		UPDATE citamedica SET pacienteID = NULL 
			WHERE pacienteID = usuarioID AND fechaCita = citFecha AND especialidadCita = citEspecialidad;
    END $$
DELIMITER ;


# 3. -------------------------------------- Un usuario que necesita agendar alguna cita ----------------------------------------------------
DROP PROCEDURE IF EXISTS pas_add_cita_medica;
DELIMITER $$
CREATE PROCEDURE pas_add_cita_medica(IN usuarioID INT, IN fechaCita DATETIME, IN especialidadCita VARCHAR(45))
	BEGIN
		UPDATE citamedica SET pacienteID = usuarioID 
			WHERE fechaCita = citFecha AND especialidadCita = citEspecialidad;
    END $$
DELIMITER ;


# 4. ---------------------------------- Ver el resultado de cada cita medica de algun usuario -----------------------------------------------
DROP PROCEDURE IF EXISTS pas_check_resultados;
DELIMITER $$
CREATE PROCEDURE pas_check_resultados(IN usuarioID INT)
	BEGIN
		SELECT * FROM vw_resultado_citamedica WHERE paciente = usuarioID;
    END $$
DELIMITER ;


# 4. --------------------------------------------- Añadir una incapacidad de un usuario -----------------------------------------------------

# Verificar que la incapacidad no ha sido ya añadida
DROP TRIGGER IF EXISTS tr_check_duplicates;
DELIMITER $$
CREATE TRIGGER tr_check_duplicates BEFORE INSERT ON incapacidad
	FOR EACH ROW
	BEGIN
		DECLARE duplicated INT;
        DECLARE msg VARCHAR(200);
		SELECT EXISTS (SELECT incID FROM incapacidad 
            WHERE perID = NEW.perID AND incEnfermedad = NEW.incEnfermedad
            AND incFecha = NEW.incFecha AND incDias = NEW.incDias) INTO duplicated;
        
        IF duplicated THEN
			SET msg = CONCAT('La incapacidad ya existe');
            SIGNAL sqlstate '15000' SET message_text = msg;
		END IF;
    END $$
DELIMITER ;

# Añadir una incapacidad
DROP PROCEDURE IF EXISTS pas_add_incapacidad;
DELIMITER $$
CREATE PROCEDURE pas_add_incapacidad(
	IN usuarioID INT, IN fecha DATETIME, IN enfermedad VARCHAR(45), IN dias TINYINT)
	BEGIN
		INSERT INTO incapacidad (perID, incFecha, incEnfermedad, incDias, incVerificado, incAprobado) 
			VALUES (usuarioID, fecha, enfermedad, dias, 0, 0);
    END $$
DELIMITER ;

# 5. --------------------------------------------- Modificar una incapacidad de un usuario --------------------------------------------------

# Verificar que la incapacidad no haya sido ya verificada
DROP TRIGGER IF EXISTS tr_check_verification;
DELIMITER $$
CREATE TRIGGER tr_check_verification BEFORE UPDATE ON incapacidad
	FOR EACH ROW
	BEGIN
		DECLARE verificated BOOL;
        DECLARE msg VARCHAR(200);
		SELECT incVerificado INTO verificated FROM incapacidad 
            WHERE perID = OLD.perID AND incEnfermedad = OLD.incEnfermedad
            AND incFecha = OLD.incFecha AND incDias = OLD.incDias;
        
        IF verificated THEN
			SET msg = CONCAT('La incapacidad ya ha sido verificada, no se puede modificar');
            SIGNAL sqlstate '15000' SET message_text = msg;
		END IF;
    END $$
DELIMITER ;

# Añadir una incapacidad
DROP PROCEDURE IF EXISTS pas_edit_incapacidad;
DELIMITER $$
CREATE PROCEDURE pas_edit_incapacidad(
	IN incapacidadID INT, IN fecha DATETIME, IN enfermedad VARCHAR(45), IN dias TINYINT)
	BEGIN
		UPDATE incapacidad SET incFecha = fecha, incEnfermedad = enfermedad, incDias = dias
			WHERE incID = incapacidadID;
    END $$
DELIMITER ;

# 6. -------------------------------------- Ver el estado de las atenciones en salud de un usuario -----------------------------------------
DROP PROCEDURE IF EXISTS pas_view_atencionsalud;
DELIMITER $$
CREATE PROCEDURE pas_view_atencionsalud(IN usuarioID INT)
	BEGIN
		SELECT * FROM vw_atencionsalud WHERE persona = usuarioID;
    END $$
DELIMITER ;

# 7. --------------------------------------------- Añadir una atencion en salud de un usuario ---------------------------------------------

# Verificar que la atencion en salud no ha sido ya añadida
DROP TRIGGER IF EXISTS tr_check_duplicates_atsalud;
DELIMITER $$
CREATE TRIGGER tr_check_duplicates_atsalud BEFORE INSERT ON atencionensalud
	FOR EACH ROW
	BEGIN
		DECLARE duplicated INT;
        DECLARE msg VARCHAR(200);
		SELECT EXISTS (SELECT antID FROM atencionensalud
            WHERE perID = NEW.perID AND ateTipo = NEW.ateTipo
            AND ateFecha = NEW.ateFecha) INTO duplicated;
        
        IF duplicated THEN
			SET msg = CONCAT('La atencion en salud ya existe');
            SIGNAL sqlstate '15000' SET message_text = msg;
		END IF;
    END $$
DELIMITER ;

# Añadir una atencion en salud
DROP PROCEDURE IF EXISTS pas_add_atencionsalud;
DELIMITER $$
CREATE PROCEDURE pas_add_atencionsalud(
	IN usuarioID INT, IN fecha DATETIME, IN tipo VARCHAR(45))
	BEGIN
		INSERT INTO atencionensalud (perID, ateFecha, ateTipo, ateVerificado, ateAprobado) 
			VALUES (usuarioID, fecha, tipo, 0, 0);
    END $$
DELIMITER ;

# 8. --------------------------------------------- Modificar una atencion en salud de un usuario ------------------------------------------

# Verificar que la incapacidad no haya sido ya verificada
DROP TRIGGER IF EXISTS tr_check_verification_atsalud;
DELIMITER $$
CREATE TRIGGER tr_check_verification_atsalud BEFORE UPDATE ON atencionensalud
	FOR EACH ROW
	BEGIN
		DECLARE verificated BOOL;
        DECLARE msg VARCHAR(200);
		SELECT ateVerificado INTO verificated FROM atencionensalud
            WHERE perID = OLD.perID AND ateTipo = OLD.ateTipo
            AND ateFecha = OLD.ateFecha;
        
        IF verificated THEN
			SET msg = CONCAT('La atencion en salud ya ha sido verificada, no se puede modificar');
            SIGNAL sqlstate '15000' SET message_text = msg;
		END IF;
    END $$
DELIMITER ;

# Añadir una incapacidad
DROP PROCEDURE IF EXISTS pas_edit_atencionsalud;
DELIMITER $$
CREATE PROCEDURE pas_edit_atencionsalud(
	IN atencionsaludID INT, IN fecha DATETIME, IN tipo VARCHAR(45))
	BEGIN
		UPDATE atencionensalud SET ateFecha = fecha, ateTipo = tipo
			WHERE antID = atencionsaludID;
    END $$
DELIMITER ;



# 9. ----------------------------------------------------- Crear una cita medica -----------------------------------------------------------

# Verificar que el doctor seleccionado no tenga ya una cita a esa hora
DROP TRIGGER IF EXISTS tr_check_doctor;
DELIMITER $$
CREATE TRIGGER tr_check_doctor BEFORE INSERT ON citamedica
	FOR EACH ROW
    BEGIN
		DECLARE has_appointment BOOl;
        DECLARE msg VARCHAR(200);
        SELECT EXISTS (SELECT citID FROM citamedica 
        WHERE doctorID = NEW.doctorID AND citFecha = NEW.citFecha) 
        INTO has_appointment;
        IF has_appointment THEN
			SET msg = CONCAT('El doctor ya tiene una cita a dicha hora');
				SIGNAL sqlstate '14000' SET message_text = msg;
		END IF;
    END $$
DELIMITER ;

# Añadir la cita medica 
DROP PROCEDURE IF EXISTS pas_create_citamedica;
DELIMITER $$
CREATE PROCEDURE pas_create_citamedica(IN doctor INT, IN fecha DATETIME)
	BEGIN 
		DECLARE especialidad VARCHAR(52);
        SELECT salEspecializacion INTO especialidad FROM personalsalud WHERE doctor = perID;
		INSERT INTO citamedica (doctorID, citFecha, citEspecialidad) VALUES (doctor, fecha, especialidad);
    END $$
DELIMITER ;

# 10. ----------------------------------------------------- Eliminar una cita medica --------------------------------------------------------

# Verificar que no haya algun paciente con dicha cita
DROP TRIGGER IF EXISTS tr_check_paciente;
DELIMITER $$
CREATE TRIGGER tr_check_paciente BEFORE DELETE ON citamedica FOR EACH ROW
	BEGIN
		DECLARE paciente INT;
		DECLARE msg VARCHAR(200);
        
		SELECT OLD.pacienteID INTO paciente FROM citamedica WHERE citID = OLD.citID;
		IF paciente IS NOT NULL THEN
			SET msg = CONCAT('Hay un paciente ya con dicha cita');
			SIGNAL sqlstate '14000' SET message_text = msg;
		END IF;
	END $$
DELIMITER ;

# Eliminar la cita medica 
DROP PROCEDURE IF EXISTS pas_remove_citamedica;
DELIMITER $$
CREATE PROCEDURE pas_remove_citamedica(IN cita INT)
	BEGIN 
		DELETE FROM citamedica WHERE citID = cita;
    END $$
DELIMITER ; 

# 11. ----------------------------------------------- Aprobar o rechazar una incapacidad ----------------------------------------------------
DROP PROCEDURE IF EXISTS pas_approve_incapacidad;
DELIMITER $$
CREATE PROCEDURE pas_approve_incapacidad(
	IN persona INT, IN fecha DATETIME, IN enfermedad VARCHAR(45), IN desicion BOOL)
	BEGIN 
		UPDATE incapacidad SET incAprobado = desicion, incVerificado = 1
        WHERE persona = perID AND incFecha = fecha AND incEnfermedad = enfermedad;
    END $$
DELIMITER ;

# 12. -------------------------------------------- Aprobar o rechazar una atencion en salud -------------------------------------------------
DROP PROCEDURE IF EXISTS pas_approve_atencionsalud;
DELIMITER $$
CREATE PROCEDURE pas_approve_atencionsalud(
	IN persona INT, IN fecha DATETIME, IN tipo VARCHAR(45), IN desicion BOOL)
	BEGIN 
		UPDATE atencionensalud SET ateAprobado = desicion, ateVerificado = 1
        WHERE persona = perID AND ateFecha = fecha AND ateTipo = tipo;
    END $$
DELIMITER ;

# 13. ------------------------------------------- Agregar los resultados de una cita medica -------------------------------------------------
DROP PROCEDURE IF EXISTS pas_update_resultados;
DELIMITER $$
CREATE PROCEDURE pas_update_resultados(
	IN cita INT, IN diagnostico VARCHAR(80), IN medicamento VARCHAR(45), IN cantidad TINYINT, IN intervalos TINYINT, IN examen VARCHAR(45), 
    IN peso TINYINT, IN estatura TINYINT, IN corazon TINYINT, IN vision TINYINT)
	BEGIN 
		UPDATE citamedica SET citDiagnostico = diagnostico WHERE citID = cita;
        IF medicamento IS NOT NULL THEN
			INSERT INTO medicamentos (citID, medNombre, medCantidad, medIntervalos) VALUES (cita, medicamento, cantidad, intervalos);
		END IF;
		IF examen IS NOT NULL THEN
			INSERT INTO ordenmedica (citID, ordExamen) VALUES (cita, examen);
        END IF;
        INSERT INTO evaluacionfisica (citID, evaPeso, evaEstatura, evaRitmoCardiaco, evaVision) VALUES (cita, peso, estatura, corazon, vision);
    END $$
DELIMITER ;

# 14. -------------------------------------- Modificar el perfil de riesgo integral de un usuario -------------------------------------------
DROP PROCEDURE IF EXISTS pas_edit_perfilintegral;
DELIMITER $$
CREATE PROCEDURE pas_edit_perfilintegral(IN persona INT, IN fisico INT, IN psicologico INT)
	BEGIN 
		UPDATE perfilriesgointegral SET perSaludFisica = fisico, perSaludPsicologica = psicologico
        WHERE persona = perID;
    END $$
DELIMITER ;

#--------------------------------------------------------------------------------------------------------------------------------------------
#																	Carlos
#--------------------------------------------------------------------------------------------------------------------------------------------

# PAS:
# 1. -------------------------------------- Verificar que un estudiante puede participar de una convocatoria -------------------------------------------
drop procedure if exists pas_estudiante_accede_conv;
DELIMITER $$
create procedure pas_estudiante_accede_conv(in estPapa double, in convPapa double )
begin
	declare msg varchar(100);
    if (estPapa < convPapa) then
		set msg = concat('El estudiante no puede participar de la convocatoria.');
	else 
		set msg = concat('El estudiante puede participar de la convocatoria.');
	end if;
    select msg;
end $$
DELIMITER ;

# 2. -------------------------------------- Consultar el lugar de un Evento/Taller -------------------------------------------
drop procedure if exists pas_consultar_lugar_eveta;
DELIMITER $$
create procedure pas_consultar_lugar_eveta(in nomEveta varchar (60))
begin
	select evetaLugar from EventoTaller where nomEveta = evetaNombre;
end $$
DELIMITER ;

# 3. -------------------------------------- Verificar viabilidad de un proyecto de acuerdo a un presupuesto -------------------------------------------

drop procedure if exists pas_check_proyecto;
DELIMITER $$
create procedure pas_check_proyecto(in idProyecto int, in presupuestoDado int)
begin
	declare msg varchar (100);
    declare presProyecto int;
    select proyPresupuesto into presProyecto from Proyecto where proyidProyecto = idProyecto;
    if (presProyecto > presupuestoDado) then
		set msg = concat('Su proyecto no es viable, excede el presupuesto.');
	else
		set msg = concat('Su proyecto es viable, puede insertarse en la tabla de proyectos.');
	end if;
end $$
DELIMITER ;

# 4. -------------------------------------- Un área quiere consultar cuantos estudiantes se presentan por facultad a sus convocatorias------------------

drop procedure if exists pas_consultar_num_estudiantes;
DELIMITER $$
create procedure pas_consultar_num_estudiantes(in idArea int)
begin
	select count(distinct estID) from (Area join Programa on (areID = Area_areID)) join 
    ((Estudiante join Estudiante_Toma_Convocatoria on (estID = idEst)) join Convocatoria using (conv_id))
    on (progID = Programa_progID) where idArea = areID group by estFacultad;
end $$
DELIMITER ;

# 5. --------------------------------------- Agregar una nueva convocatoria a cursos libres y selecciones  ------------------

drop procedure if exists pas_agregar_convocatoria_cur_libre;
DELIMITER $$
create procedure pas_agregar_convocatoria_cur_libre(in idConv int, in nombreConv varchar(70), in fechaA DATE, in fechaC DATE, in edo tinyint, 
													in idPrograma int, in papaConv double, in tipo VARCHAR(45), in condicion VARCHAR(45))
begin
	insert into Convocatoria (conv_id, convNombre, convFechaApertura, convFechaCierre, convEstado, convPeriodo, Programa_progID, convPAPA)
    values (idConv,nombreConv,fechaA,fechaC,edo,idPrograma,papaConv);
    
    insert into ConvocatoriaCursoLibre (Convocatoria_conv_id, curNombre, curTipoCurso, curCondicion) values (idConv, nombreConv, tipo, condicion);
end $$
DELIMITER ;
  
drop procedure if exists pas_agregar_convocatoria_seleccion;
DELIMITER $$
create procedure pas_agregar_convocatoria_cur_libre(in idConv int, in nombreConv varchar(70), in fechaA DATE, in fechaC DATE, in edo tinyint, 
													in idPrograma int, in papaConv double, in deporte VARCHAR(45), in lugar VARCHAR(45), hora TIME)
begin
	insert into Convocatoria (conv_id, convNombre, convFechaApertura, convFechaCierre, convEstado, convPeriodo, Programa_progID, convPAPA)
    values (idConv,nombreConv,fechaA,fechaC,edo,idPrograma,papaConv);
    
    insert into ConvocatoriaCursoLibre (Convocatoria_conv_id, convDeporte, convLugar, convHora) values (idConv, deporte, lugar, hora);
end $$
DELIMITER ;

# 6. --------------------------------------- Actualizar tiempo y lugar de distintas tablas ------------------------------------------

# Torneo Interno:
drop procedure if exists pas_actualizar_fecha_torneo;
DELIMITER $$
create procedure pas_actualizar_fecha_torneo (in idTorneo int, in nuevaFechaInicio date, in nuevaFechaFin date)
begin
	update TorneoInterno set torFechaInicio = nuevaFechaInicio where idTorneo = toridTorneoInterno;
    update TorneoInterno set torFechaFinalizacion = nuevaFechaFin where idTorneo = toridTorneoInterno;
end $$
DELIMITER ;


# ConvocatoriaSeleccion

drop procedure if exists pas_actualizar_hora_convSeleccion;
DELIMITER $$
create procedure pas_actualizar_hora_convSeleccion(in idConv int ,in nuevaHora time)
begin
	update ConvocatoriaSeleccion set convLugar = nuevaHora where idConv = Convocatoria_convid;
end $$
DELIMITER ;

drop procedure if exists pas_actualizar_lugar_convSeleccion;
DELIMITER $$
create procedure pas_actualizar_lugar_convSeleccion(in idConv int ,in nuevoLugar varchar(50))
begin
	update ConvocatoriaSeleccion set convLugar = nuevoLugar where idConv = Convocatoria_convid;
end $$
DELIMITER ;


# Evento Taller:

drop procedure if exists pas_actualizar_fecha_eventoTaller;
DELIMITER $$
create procedure pas_actualizar_fecha_eventoTaller (in idEveTa int, in nuevaFecha date)
begin
	update EventoTaller set evetaFecha = nuevaFecha where evetaidEventoTaller = idEveTa;
end $$
DELIMITER ;

drop procedure if exists pas_actualizar_lugar_eventoTaller;
DELIMITER $$
create procedure pas_actualizar_lugar_eventoTaller (in idEveTa int, in nuevoLugar date)
begin
	update EventoTaller set evetaLugar = nuevoLugar where evetaidEventoTaller = idEveTa;
end $$
DELIMITER ;

drop procedure if exists pas_actualizar_hora_eventoTaller;
DELIMITER $$
create procedure pas_actualizar_lugar_eventoTaller (in idEveTa int, in nuevaHoraInicio datetime, in nuevaHoraFin datetime)
begin
	update EventoTaller set evetaHoraInicio = nuevaHoraInicio where evetaidEventoTaller = idEveTa;
    update EventoTaller set evetaHoraFin = nuevaHoraFin where evetaidEventoTaller = idEveTa;
end $$
DELIMITER ;


# Proyecto:

drop procedure if exists pas_actualizar_fechas_proyecto;
DELIMITER $$
create procedure pas_actualizar_fechas_proyecto(in idProyecto int, in nuevaFechaInicio date, in nuevaFechaFin date)
begin
	update Proyecto set proyFechaInicio = nuevaFechaInicio where idProyecto = proyIdProyecto;
    update Proyecto set proyFechaFinalizacion = nuevaFechaFin where idProyecto = proyIdProyecto;
end $$
DELIMITER ;

# 7. --------------------------------------- Actualizar ejecucion de un proyecto ------------------------------------------

drop procedure if exists pas_actualizar_ejecucion_proyecto;
DELIMITER $$
create procedure pas_actualizar_fechas_proyecto(in idProyecto int, in nuevaEjecucion decimal)
begin
	update Proyecto set proyEjecucion = nuevaEjecucion where idProyecto = proyIdProyecto;
end $$
DELIMITER ;

# 8. --------------------------------------- Agregar un nuevo torneo interno  ---------------------------------------------

drop procedure if exists pas_agregar_nuevo_torneo;
DELIMITER $$
create procedure pas_agregar_nuevo_torneo(in idTorneo int, in periodo varchar(10), in sedeFacultad varchar(60), in deporte varchar(35), in nombreTorneo varchar (90),
										in estado TINYINT, in modalidad VARCHAR(45), in rama VARCHAR(45), in nivel VARCHAR(45), in FechaInicio DATE, in FechaFinalizacion DATE
										, in idPrograma INT)
begin
	insert into TorneoInterno (toridTorneoInterno, torPeriodo, torSedeFacultad, torDeporte, torNombreTorneo, torEstado, torModalidad, torRama, torNivel
    , torFechaInicio, torFechaFinalizacion, Programa_progID) values (idTorneo, periodo, sedeFacultad, deporte, nombreTorneo, estado, modalidad, rama, nivel, FechaInicio,
    FechaFinalizacion, idPrograma);
end $$
DELIMITER ;

# 9. ---------------------------- Un programa quiere agregar nuevos proyectos, eventos, y talleres---------------------------------------


# Proyecto

drop procedure if exists pas_crear_nuevoProyecto;
DELIMITER $$
create procedure pas_crear_nuevoProyecto(in IdProyecto INT,in Nombre VARCHAR(60),in Ejecucion DECIMAL,in FechaInicio DATE, in FechaFinalizacion DATE,
										Presupuesto VARCHAR(1000), in idPrograma int)
begin
	insert into Proyecto (proyIdProyecto, proyNombre, proyEjecucion, proyFechaInicio, proyFechaFinalizacion, proyPresupuesto) values (
    IdProyecto, Nombre,  Ejecucion, FechaInicio, FechaFinalizacion, Presupuesto);
    insert into Programa_Tiene_Proyecto (Proyecto_proyIdProyecto, progID) values (proyIdProyecto, idPrograma);
    
end $$
DELIMITER ;


# EventoTaller

drop procedure if exists pas_agendar_nuevoEventoTaller;
DELIMITER $$
create procedure pas_agendar_nuevoEventoTaller(in idEventoTaller1 INT, in Nombre VARCHAR(60), in TipoEventoTaller VARCHAR(45), in Descripcion LONGTEXT,
					in HoraInicio DATETIME, in HoraFin DATETIME, in Fecha DATE, in Lugar VARCHAR(45), in idPrograma int)
begin
	insert into EventoTaller (evetaidEventoTaller, evetaNombre, evetaTipoEventoTaller, eveDescripcion, evetaHoraInicio, evetaHoraFin,
							  evetaFecha, evetaLugar) values (
    idEventoTaller1, Nombre,  TipoEventoTaller, Descripcion, HoraInicio, HoraFin, Fecha, Lugar);
    insert into Programa_Tiene_EventoTaller (idEventoTaller, progID) values (idEventoTaller1, idPrograma);
    
end $$
DELIMITER ;


# 10. ---------------------------- Se quiere consultar eventos, talleres y proyectos disponbibles ---------------------------------------





#Pendientes:
/*
1. hacer sección 10.

2. asignar permisos a los pas.

3. agregar vistas necesarias en caso tal. *
*/ 



#--------------------------------------------------------------------------------------------------------------------------------------------
#                                  									Javier
#--------------------------------------------------------------------------------------------------------------------------------------------

# 1. El estudiante puede consultar sus fallas de alimentación

drop procedure if exists sp_fallaalimentacion_est;
DELIMITER $$
CREATE PROCEDURE sp_fallaalimentacion_est(in id int)
	BEGIN
		SELECT fallAlID,fallAlcgaComida,fallAlLugar,fallAlFecha from 
			fallaalimentacion where estID=id;
	END $$
DELIMITER ;

#call sp_fallaalimentacion_est(9)

# 2. El estudiante puede consultar sus actividades de corresponsabilidad realizadas

drop procedure if exists sp_actividadcorresp_est;
DELIMITER $$
CREATE PROCEDURE sp_actividadcorresp_est(in id int)
	BEGIN
		SELECT actCorID,actCorActividad,actCorHoras from 
			actividadcorresp where estID=id;
	END $$
DELIMITER ;

#call sp_actividadcorresp_est(18);

# 3. El estudiante puede consultar la cantidad de horas pendientes de corresponsabilidad

drop function if exists horas_corresponsabilidad_est;
DELIMITER $$
CREATE FUNCTION horas_corresponsabilidad_est(id_est int)
		RETURNS int
        BEGIN
			DECLARE horas INT default 0;
            select horPendCorresp into horas from corresponsabilidad where idEst=id_est;
		RETURN horas;
	END $$
DELIMITER ;

#set @horas =  horas_corresponsabilidad_est(4);
#select @horas;


#4. El estudiante desea conocer su PBM

drop function if exists pbm_est;
DELIMITER $$
CREATE FUNCTION pbm_est(id_est int)
		RETURNS int
        BEGIN
			DECLARE pbm INT default 0;
            select estPBM into pbm from estudiante where estID=id_est;
		RETURN pbm;
	END $$
DELIMITER ;

#set @pbm =  pbm_est(10);
#select @pbm;

# 5. El estudiante solo desea visualizar las convocatorias a las que podría acceder según su PBM:

#5.1 La convocatoria fomento emprendimeinto la busca según tema

drop procedure if exists sp_convocatoriafomentoemprendimeinto_est;
DELIMITER $$
CREATE PROCEDURE sp_convocatoriafomentoemprendimeinto_est(in id_est int, in tema varchar(50))
	BEGIN
		select * from convocatoriafomentoemprendimeinto where LOCATE(LOWER(tema), LOWER(cgemTema)) > 0;
	END $$
DELIMITER ;

#call sp_convocatoriafomentoemprendimeinto_est(5,'tema2')


#5.2 La convocatoria de gestión alimentaria solo se puede acceder con PBM < 25

drop procedure if exists sp_convocatoriagestionalimentaria_est;
DELIMITER $$
CREATE PROCEDURE sp_convocatoriagestionalimentaria_est(in id_est int, in comida enum('Desayuno','Almuerzo','Cena'), in lugar enum('Comedor central','Hemeroteca','Odontología','Agronomía','Biología','Ciencias Humanas','Ciencias Económicas','Matemáticas','otro'))
	BEGIN
		if pbm_est(id_est)<26 then
			select * from convocatoriagestionalimentaria where cgaComida=comida and cgaLugar=lugar;
		else
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El PBM del estaudiante es mayor que 25: No tiene acceso de convocatorias de gestión alimentaria';
        end if;
	END $$
DELIMITER ;

/*
set @pbm =  pbm_est(10);
select @pbm;
call sp_convocatoriagestionalimentaria_est(10,'Desayuno','Comedor central');
set @pbm =  pbm_est(5);
select @pbm;
call sp_convocatoriagestionalimentaria_est(5,'Desayuno','Comedor central');
*/


#5.3 La convocatoria de gestión alojamiento solo se puede acceder con PBM < 25

drop procedure if exists sp_convocatoriagestionalojamiento_est;
DELIMITER $$
CREATE PROCEDURE sp_convocatoriagestionalojamiento_est(in id_est int, in localidad varchar(100), in tipo enum('Hotel','Casa','Apartamento','Vivienda familiar','Residencia Universitaria','Apartaestudio','Habitación','otro'))
	BEGIN
		if pbm_est(id_est)<26 then
			select * from convocatoriagestionalojamiento where LOCATE(LOWER(localidad), LOWER(cgalLocalidadAlojamiento)) > 0 and tipo=cgalTipoVivienda;
		else
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El PBM del estaudiante es mayor que 25: No tiene acceso de convocatorias de gestión alojamiento';
        end if;
	END $$
DELIMITER ;

/*
set @pbm =  pbm_est(10);
select @pbm;
call sp_convocatoriagestionalojamiento_est(10,'Usme','Residencia Universitaria');
set @pbm =  pbm_est(5);
select @pbm;
call sp_convocatoriagestionalojamiento_est(5,'Usme','Residencia Universitaria');
*/


#5.4 La convocatoria de gestión economica solo se puede acceder con PBM < 20

drop procedure if exists sp_convocatoriagestioneconomica_est;
DELIMITER $$
CREATE PROCEDURE sp_convocatoriagestioneconomica_est(in id_est int)
	BEGIN
		if pbm_est(id_est)<21 then
			select * from convocatoriagestioneconomica order by cgeCobertura;
		else
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El PBM del estaudiante es mayor que 20: No tiene acceso de convocatorias de gestión económica';
        end if;
	END $$
DELIMITER ;

/*
set @pbm =  pbm_est(10);
select @pbm;
call sp_convocatoriagestioneconomica_est(10);
set @pbm =  pbm_est(5);
select @pbm;
call sp_convocatoriagestioneconomica_est(5);
*/


#5.5 La convocatoria de gestión transporte solo se puede acceder con PBM < 15

drop procedure if exists sp_convocatoriagestiontransporte_est;
DELIMITER $$
CREATE PROCEDURE sp_convocatoriagestiontransporte_est(in id_est int, in tipo enum('Transporte público masivoTransporte público masivo','otro'))
	BEGIN
		if pbm_est(id_est)<16 then
			select * from convocatoriagestiontransporte where cgtTipoTransporte=tipo order by cgtCobertura;
		else
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El PBM del estaudiante es mayor que 15: No tiene acceso de convocatorias de gestión transporte';
        end if;
	END $$
DELIMITER ;

/*
set @pbm =  pbm_est(10);
select @pbm;
call sp_convocatoriagestiontransporte_est(10, 'Transporte público masivo');
set @pbm =  pbm_est(5);
select @pbm;
call sp_convocatoriagestiontransporte_est(5, 'Transporte público masivo');
*/

#6. Una persona/estudiante/secretario/director quiere consultar sus facturas con los detalles en la Tienda de bienestar U.

drop procedure if exists sp_info_factura_per;
DELIMITER $$
CREATE PROCEDURE sp_info_factura_per(in id_per int, in id_tienda int)
	BEGIN
		select * from vw_info_factura where clienteID=id_per and tieID=id_tienda;
	END $$
DELIMITER ;

#call sp_info_factura_per(14, 2)

#7. Una persona quiere consultar los productos en una tienda de bienestar U.

drop procedure if exists sp_productos_tienda;
DELIMITER $$
CREATE PROCEDURE sp_productos_tienda(in id_tienda int)
	BEGIN
		select * from  vw_productos_tienda where tieID=id_tienda;
	END $$
DELIMITER ;

#call sp_productos_tienda(1)

# 8. Una persona queire conocer las tiendas donde se encuentra un producto

drop procedure if exists sp_tiendas_ofrece_producto;
DELIMITER $$
CREATE PROCEDURE sp_tiendas_ofrece_producto(in id_prod int)
	BEGIN
		select tieID,tieDireccion,tieCiudad from vw_productos_tienda where prodID=id_prod;
	END $$
DELIMITER ;

/*
select * from vw_productos_tienda;
call sp_tiendas_ofrece_producto(9); #1 resultado
call sp_tiendas_ofrece_producto(11); #2 resultados
*/

# 9. Si el estudiante inserta una conv. en est_toma_conv, verificar que no ingrese
#dos veces la misma en el mismo semestre

drop procedure if exists sp_insertar_est_tm_conv_est;
DELIMITER $$
CREATE PROCEDURE sp_insertar_est_tm_conv_est(in id_est int, in id_conv int, in fecha DATE)
	BEGIN
		declare existe_conv int;
        declare msg char(250);
		#Primer semstre
		if CAST(Month(fecha) as unsigned)>0 and CAST(Month(fecha) as unsigned)<7 then
			drop table if exists temp_table;
			CREATE TEMPORARY TABLE temp_table as select conv_id from estudiante_toma_convocatoria 
				where idEst=id_est and YEAR(fecha_est_tm_conv)=YEAR(fecha) and CAST(MONTH(fecha_est_tm_conv) AS UNSIGNED)>0 
                and CAST(MONTH(fecha_est_tm_conv) AS UNSIGNED)<7;
			select conv_id into existe_conv from temp_table where conv_id=id_conv;
            if existe_conv is null then
				insert into estudiante_toma_convocatoria values (id_est,id_conv,fecha);
			else
                SET msg = CONCAT('El estudiante con id ',id_est, ' ya se encuentra inscrito a la convocatoria ', id_conv, 
                ' para el periodo ', YEAR(fecha), '-1');
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
			end if;
		else
			drop table if exists temp_table;
			CREATE TEMPORARY TABLE temp_table as select conv_id from estudiante_toma_convocatoria 
				where idEst=id_est and YEAR(fecha_est_tm_conv)=YEAR(fecha) and CAST(MONTH(fecha_est_tm_conv) AS UNSIGNED)>6 
                and CAST(MONTH(fecha_est_tm_conv) AS UNSIGNED)<13;
			select conv_id into existe_conv from temp_table where conv_id=id_conv;
            if existe_conv is null then
				insert into estudiante_toma_convocatoria values (id_est,id_conv,fecha);
			else
                SET msg = CONCAT('El estudiante con id ',id_est, ' ya se encuentra inscrito a la convocatoria ', id_conv, 
                ' para el periodo ', YEAR(fecha), '-2');
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
			end if;
		end if;
	END $$
DELIMITER ;

/*
call sp_insertar_est_tm_conv_est(9, 210 ,'2023-03-15');
call sp_insertar_est_tm_conv_est(9, 211 ,'2023-03-15');

call sp_insertar_est_tm_conv_est(13, 1 ,'2023-07-13');
call sp_insertar_est_tm_conv_est(13, 2 ,'2023-07-13');
select * from estudiante_toma_convocatoria;
*/

# 10. El secretario/dirección quieren actualizar las convoctarias de un programa

select * from convocatoria;
select * from programa;


# 12. La dirección económica quiere eliminar convocatorias económicas, pero para hacerlo 
#debe eliminar primero el registro de la  tabla de convocarorias

# 13

# 14

# 15

# 16

# 17

# 18

# 19

# 20

/*

#--------------------------------------------------------------------------------------------------------------------------------------------
#																	PAS_interfaz
#--------------------------------------------------------------------------------------------------------------------------------------------

# Uso General:

# ------------------------------- Un usuario necesita ver todas las convocatorias por área ----------------------------------------------
drop procedure if exists sp_consultar_convocatorias_area;
DELIMITER $$
create procedure sp_consultar_programas_de_deportes(in idArea int)
	begin 
		select * from vw_info_convocatoria where areID = idArea;
	end $$
DELIMITER ;


# ------------------------------- Un estudiante necesita ver las convocatorias por programa de area de bienestar ----------------------------------------------
drop procedure if exists sp_consultar_convocatorias_programa;
DELIMITER $$
create procedure sp_consultar_convocatorias_deporte(in idPrograma int)
	begin 
		select * from Convocatoria where Programa_progID = id_Programa;
	end $$
DELIMITER ;

# ------------------------------- Un estudiante necesita ver las convocatorias en las que participa ----------------------------------------------
drop procedure if exists sp_consultar_mis_convocatorias;
DELIMITER $$
create procedure sp_consultar_mis_convocatorias (in cedula int)
	begin
		select * from vw_info_convocatoria_estudiante where estID = cedula;
	end $$
DELIMITER ;


# Salud

# --------------------------------------------- Ver perfil de riesgo integral de un usuario --------------------------------------------
DROP PROCEDURE IF EXISTS pas_view_perfilriesgo;
DELIMITER $$
CREATE PROCEDURE pas_view_perfilriesgo(IN usuarioID INT)
	BEGIN
		SELECT * FROM vw_perfil_integral WHERE persona = usuarioID;
    END $$
DELIMITER ;

# -------------------------------------- Ver el estado de las incapacidades de un usuario ------------------------------------------------
DROP PROCEDURE IF EXISTS pas_view_incapacidad;
DELIMITER $$
CREATE PROCEDURE pas_view_incapacidad(IN usuarioID INT)
	BEGIN
		SELECT * FROM vw_incapacidad WHERE persona = usuarioID;
    END $$
DELIMITER ;

# ------------------------------- Un usuario que necesita ver las citas medicas disponibles ----------------------------------------------
DROP PROCEDURE IF EXISTS pas_citas_disponibles;
DELIMITER $$
CREATE PROCEDURE pas_citas_disponibles()
	BEGIN 
		SELECT * FROM vw_citamedica_disponible;
    END $$
DELIMITER ;


# Actividad Física y Deporte

# ------------------------------- Un usuario necesita ver los torneos internos disponibles ----------------------------------------------
drop procedure if exists sp_consultar_torneos_internos;
DELIMITER $$
create procedure sp_consultar_torneos_internos()
	begin 
		select * from TorneoInterno;
	end $$
DELIMITER ;

# ------------------------------- Un usuario necesita ver los cursos libres de deportes disponibles ----------------------------------------------
drop procedure if exists sp_consultar_convocatoria_cursos_libres;
DELIMITER $$
create procedure sp_consultar_convocatoria_cursos_libres()
	begin 
		select * from ConvocatoriaCursoLibre;
	end $$
DELIMITER ;


# Gestión y Fomento Socioeconómico

# ------------------------------- Un usuario necesita ver información detallada de convocatorias de fomento, por tipo de apoyo.-----------------------
drop procedure if exists sp_consultar_gestion_alimentaria;
DELIMITER $$
create procedure sp_consultar_gestion_alimentaria ()
	begin
		select * from ConvocatoriaGestionAlimentaria join Convocatoria on (conv_id);
	end $$
DELIMITER ;

drop procedure if exists sp_consultar_gestion_transporte;
DELIMITER $$
create procedure sp_consultar_gestion_transporte ()
	begin
		select * from ConvocatoriaGestionTransporte join Convocatoria on (conv_id);
	end $$
DELIMITER ;

drop procedure if exists sp_consultar_gestion_alojamiento;
DELIMITER $$
create procedure sp_consultar_gestion_alojamiento()
	begin
		select * from ConvocatoriaGestionAlojamiento join Convocatoria on (conv_id);
	end $$
DELIMITER ;

drop procedure if exists sp_consultar_gestion_economica;
DELIMITER $$
create procedure sp_consultar_gestion_economica ()
	begin
		select * from ConvocatoriaGestionEconomica join Convocatoria on (conv_id);
	end $$
DELIMITER ;

drop procedure if exists sp_consultar_gestion_emprendimiento;
DELIMITER $$
create procedure sp_consultar_gestion_emprendimiento ()
	begin
		select * from ConvocatoriaFomentoEmprendimeinto join Convocatoria on (conv_id);
	end $$
DELIMITER ;
*/