--------------- SQL ---------------

CREATE OR REPLACE FUNCTION conta.f_get_config_relacion_contable (
  p_codigo varchar,
  p_id_gestion integer,
  p_id_tabla integer = NULL::integer,
  p_id_centro_costo integer = NULL::integer,
  out ps_id_cuenta integer,
  out ps_id_auxiliar integer,
  out ps_id_partida integer
)
RETURNS SETOF record AS
$body$
/*
Autor Rensi Arteaga Copari
Fecha 01/07/2013
Descripcion: recupera la la parametrizacion de la relacion contable indicada

ejmplo


 SELECT 
              ps_id_partida ,
              ps_id_cuenta,
              ps_id_auxiliar
            into 
              v_id_partida,
              v_id_cuenta, 
              v_id_auxiliar
          FROM conta.f_get_config_relacion_contable('CUECOMP', v_id_gestion, v_parametros.id_concepto_ingas, v_parametros.id_centro_costo);
          
        


*/
DECLARE
v_nombre_funcion varchar;
v_resp varchar;
v_registros record;
	
BEGIN
	
    
    v_nombre_funcion:='conta.f_get_config_relacion_contable';
    
     ps_id_cuenta = NULL;
     ps_id_auxiliar=NULL;
     ps_id_partida=NULL;
    
    
    --1)  recuperamos el tipo de relacion
    
    SELECT 
      trc.id_tipo_relacion_contable,
      trc.id_tabla_relacion_contable,
      trc.tiene_centro_costo
    into 
      v_registros  
    from conta.ttipo_relacion_contable trc 
    where trc.codigo_tipo_relacion = p_codigo 
      and trc.estado_reg = 'activo'; 
    
    
    raise notice '%, % ,%', v_registros.tiene_centro_costo,v_registros.id_tabla_relacion_contable,v_registros.id_tipo_relacion_contable;
    
     IF p_id_centro_costo is NULL THEN
                
        raise exception 'El tipo de relacion relacion contable indica que necesita  centro de costo';
              
     END IF;
    
   --  preguntamos si el tipo de relacion necesita o no necesita tabla de configuracion
   
   IF  v_registros.id_tabla_relacion_contable is NULL THEN
     --  si no necesita, obtiene el valor para la gestion indica 
     
         IF   v_registros.tiene_centro_costo = 'no' THEN 
           
           select
              rc.id_cuenta,
              rc.id_auxiliar,
              rc.id_partida
           into
              ps_id_cuenta,
              ps_id_auxiliar,
              ps_id_partida
           from conta.trelacion_contable rc 
           where  
              rc.id_tipo_relacion_contable =  v_registros.id_tipo_relacion_contable
              and rc.id_gestion = p_id_gestion
              and rc.estado_reg = 'activo'
              and rc.id_centro_costo is NULL
              LIMIT 1  OFFSET 0;
          
          ELSEIF v_registros.tiene_centro_costo = 'si' THEN
              
               select
                  rc.id_cuenta,
                  rc.id_auxiliar,
                  rc.id_partida
               into
                  ps_id_cuenta,
                  ps_id_auxiliar,
                  ps_id_partida
               from conta.trelacion_contable rc 
               where  
                  rc.id_tipo_relacion_contable=  v_registros.id_tipo_relacion_contable
                  and rc.id_gestion = p_id_gestion
                  and rc.estado_reg = 'activo'
                  and rc.id_centro_costo = p_id_centro_costo
                  LIMIT 1  OFFSET 0;
          
          
          ELSEIF v_registros.tiene_centro_costo = 'si-general' THEN
          
             raise notice 'si-general';
            
            -- es caso de ser si general primero buscamos una configuracion con centro de costos
            -- si no la encontramos buscamos una general, sin centro de costo (la especifica prevalece sobre la general)
            
               select
                  rc.id_cuenta,
                  rc.id_auxiliar,
                  rc.id_partida
               into
                  ps_id_cuenta,
                  ps_id_auxiliar,
                  ps_id_partida
               from conta.trelacion_contable rc 
               where  
                  rc.id_tipo_relacion_contable=  v_registros.id_tipo_relacion_contable
                  and rc.id_gestion = p_id_gestion
                  and rc.estado_reg = 'activo'
                  and rc.id_centro_costo = p_id_centro_costo
                  LIMIT 1  OFFSET 0;
            
     
               IF ps_id_cuenta is NULL THEN
               --buscamos una configuracion general sin centro de costo
                     select
                        rc.id_cuenta,
                        rc.id_auxiliar,
                        rc.id_partida
                     into
                        ps_id_cuenta,
                        ps_id_auxiliar,
                        ps_id_partida
                     from conta.trelacion_contable rc 
                     where  
                        rc.id_tipo_relacion_contable =  v_registros.id_tipo_relacion_contable
                        and rc.id_gestion = p_id_gestion
                        and rc.estado_reg = 'activo'
                        and rc.id_centro_costo is NULL
                        LIMIT 1  OFFSET 0;
                END IF;
           ELSE
          
             raise exception 'valor para la variable  "tiene_centro_costo" desconocido';
          
          END IF; 
   ELSE
         
         --si necesita tabla de configuracion el parametros p_tabla y p_id_tabla no pueden ser nulos
          raise notice 'la tabla de la relacion  contable es no nulo';
          IF p_id_tabla is NULL THEN
            raise exception 'Este tipo de relacion contable necesita indicar la tabla y el id para busquedas';
          END IF;
          
          
          IF   v_registros.tiene_centro_costo = 'no' THEN 
           
               select
                  rc.id_cuenta,
                  rc.id_auxiliar,
                  rc.id_partida
               into
                  ps_id_cuenta,
                  ps_id_auxiliar,
                  ps_id_partida
               from conta.trelacion_contable rc 
               where  
                  rc.id_tipo_relacion_contable =  v_registros.id_tipo_relacion_contable
                  and rc.id_gestion = p_id_gestion
                  and rc.estado_reg = 'activo'
                  and rc.id_centro_costo is NULL
                  and rc.id_tabla = p_id_tabla
                  LIMIT 1  OFFSET 0;
          
          ELSEIF v_registros.tiene_centro_costo = 'si' THEN
                
                 select
                    rc.id_cuenta,
                    rc.id_auxiliar,
                    rc.id_partida
                 into
                    ps_id_cuenta,
                    ps_id_auxiliar,
                    ps_id_partida
                 from conta.trelacion_contable rc 
                 where  
                    rc.id_tipo_relacion_contable=  v_registros.id_tipo_relacion_contable
                    and rc.id_gestion = p_id_gestion
                    and rc.estado_reg = 'activo'
                    and rc.id_centro_costo = p_id_centro_costo
                    and rc.id_tabla = p_id_tabla
                    LIMIT 1  OFFSET 0;
          
          
          ELSEIF v_registros.tiene_centro_costo = 'si-general' THEN
            -- es caso de ser si general primero buscamos una configuracion con centro de costos
            -- si no la encontramos buscamos una general, sin centro de costo (la especifica prevalece sobre la general)
            raise notice 'si-general';
            
               select
                  rc.id_cuenta,
                  rc.id_auxiliar,
                  rc.id_partida
               into
                  ps_id_cuenta,
                  ps_id_auxiliar,
                  ps_id_partida
               from conta.trelacion_contable rc 
               where  
                  rc.id_tipo_relacion_contable=  v_registros.id_tipo_relacion_contable
                  and rc.id_gestion = p_id_gestion
                  and rc.estado_reg = 'activo'
                  and rc.id_centro_costo = p_id_centro_costo
                  and rc.id_tabla = p_id_tabla
                  LIMIT 1  OFFSET 0;
            
     
               IF ps_id_cuenta is NULL THEN
               --buscamos una configuracion general sin centro de costo
               raise notice 'no hay una configuracion con centro de costo';
                     select
                        rc.id_cuenta,
                        rc.id_auxiliar,
                        rc.id_partida
                     into
                        ps_id_cuenta,
                        ps_id_auxiliar,
                        ps_id_partida
                     from conta.trelacion_contable rc 
                     where  
                        rc.id_tipo_relacion_contable =  v_registros.id_tipo_relacion_contable
                        and rc.id_gestion = p_id_gestion
                        and rc.estado_reg = 'activo'
                        and rc.id_centro_costo is NULL
                        and rc.id_tabla = p_id_tabla
                        LIMIT 1  OFFSET 0;
                        
                END IF;
         END IF;
   
   END IF;
   
   raise notice 'ps_id_cuenta %,  ps_id_auxiliar %,  ps_id_partida %', ps_id_cuenta,ps_id_auxiliar, ps_id_partida;

return NEXT;
return;

   
EXCEPTION
WHEN OTHERS THEN 
			v_resp='';
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
			v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
			v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
			raise exception '%',v_resp;
END;
$body$
LANGUAGE 'plpgsql'
STABLE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1;