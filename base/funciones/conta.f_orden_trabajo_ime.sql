CREATE OR REPLACE FUNCTION conta.f_orden_trabajo_ime (
  p_administrador integer,
  p_id_usuario integer,
  p_tabla varchar,
  p_transaccion varchar
)
RETURNS varchar AS
$body$
/**************************************************************************
 SISTEMA:		Sistema de Contabilidad
 FUNCION: 		conta.f_orden_trabajo_ime
 DESCRIPCION:   Funcion que gestiona las operaciones basicas (inserciones, modificaciones, eliminaciones de la tabla 'conta.torden_trabajo'
 AUTOR: 		Gonzalo Sarmiento Sejas
 FECHA:	        21-02-2013 21:08:55
 COMENTARIOS:	
***************************************************************************
 HISTORIAL DE MODIFICACIONES:

 DESCRIPCION:	
 AUTOR:			
 FECHA:		
***************************************************************************/

DECLARE

	v_nro_requerimiento    	integer;
	v_parametros           	record;
	v_id_requerimiento     	integer;
	v_resp		            varchar;
	v_nombre_funcion        text;
	v_mensaje_error         text;
	v_id_orden_trabajo	integer;
    v_orden					record;
    v_query					text;
			    
BEGIN

    v_nombre_funcion = 'conta.f_orden_trabajo_ime';
    v_parametros = pxp.f_get_record(p_tabla);

	/*********************************    
 	#TRANSACCION:  'CONTA_ODT_INS'
 	#DESCRIPCION:	Insercion de registros
 	#AUTOR:		Gonzalo Sarmiento Sejas
 	#FECHA:		21-02-2013 21:08:55
	***********************************/

	if(p_transaccion='CONTA_ODT_INS')then
					
        begin
        	
        	
            --Sentencia de la insercion
        	insert into conta.torden_trabajo(
			estado_reg,
			fecha_final,
			fecha_inicio,
			desc_orden,
			motivo_orden,
			fecha_reg,
			id_usuario_reg,
			id_usuario_mod,
			fecha_mod
          	) values(
			'activo',
			v_parametros.fecha_final,
			v_parametros.fecha_inicio,
			v_parametros.desc_orden,
			v_parametros.motivo_orden,
			now(),
			p_id_usuario,
			null,
			null
							
			)RETURNING id_orden_trabajo into v_id_orden_trabajo;
			
            if (pxp.f_get_variable_global('sincronizar') = 'true') then
                	                    
                    select * FROM dblink(migra.f_obtener_cadena_conexion(), 
                        'SELECT * 
                        FROM sci.f_tct_orden_trabajo_iud(' || p_id_usuario || ',''' ||
                        		pxp.f_get_variable_global('sincroniza_ip') || ''',''Sincronizacion'',''CT_ORDTRA_INS'',NULL,' || v_id_orden_trabajo || ',' ||
                                coalesce ('''' || v_parametros.desc_orden::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_parametros.motivo_orden::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_parametros.fecha_inicio::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_parametros.fecha_final::text || '''', 'NULL') || ',1,' ||p_id_usuario||
                                ')',TRUE)AS t1(resp varchar)
                                into v_resp; 
            end if;
            
			--Definicion de la respuesta
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Ordenes de Trabajo almacenado(a) con exito (id_orden_trabajo'||v_id_orden_trabajo||')'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_orden_trabajo',v_id_orden_trabajo::varchar);

            --Devuelve la respuesta
            return v_resp;

		end;

	/*********************************    
 	#TRANSACCION:  'CONTA_ODT_MOD'
 	#DESCRIPCION:	Modificacion de registros
 	#AUTOR:		Gonzalo Sarmiento Sejas	
 	#FECHA:		21-02-2013 21:08:55
	***********************************/

	elsif(p_transaccion='CONTA_ODT_MOD')then

		begin
			--Sentencia de la modificacion
			update conta.torden_trabajo set
			fecha_final = v_parametros.fecha_final,
			fecha_inicio = v_parametros.fecha_inicio,
			desc_orden = v_parametros.desc_orden,
			motivo_orden = v_parametros.motivo_orden,
			id_usuario_mod = p_id_usuario,
			fecha_mod = now()
			where id_orden_trabajo=v_parametros.id_orden_trabajo;
            
            if (pxp.f_get_variable_global('sincronizar') = 'true') then
                	                
                    select * FROM dblink(migra.f_obtener_cadena_conexion(), 
                        'SELECT * 
                        FROM sci.f_tct_orden_trabajo_iud(' || p_id_usuario || ',''' ||
                        		pxp.f_get_variable_global('sincroniza_ip') || ''',''Sincronizacion'',''CT_ORDTRA_UPD'',NULL,' || v_parametros.id_orden_trabajo || ',' ||
                                coalesce ('''' || v_parametros.desc_orden::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_parametros.motivo_orden::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_parametros.fecha_inicio::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_parametros.fecha_final::text || '''', 'NULL') || ',1,' ||p_id_usuario||
                                ')',TRUE)AS t1(resp varchar)
                                into v_resp; 
                   
            end if;
               
			--Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Ordenes de Trabajo modificado(a)'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_orden_trabajo',v_parametros.id_orden_trabajo::varchar);
               
            --Devuelve la respuesta
            return v_resp;
            
		end;

	/*********************************    
 	#TRANSACCION:  'CONTA_ODT_ELI'
 	#DESCRIPCION:	Eliminacion de registros
 	#AUTOR:		Gonzalo Sarmiento Sejas	
 	#FECHA:		21-02-2013 21:08:55
	***********************************/

	elsif(p_transaccion='CONTA_ODT_ELI')then

		begin
        	
			--Sentencia de la eliminacion
			update conta.torden_trabajo
            set estado_reg = 'inactivo'
            where id_orden_trabajo=v_parametros.id_orden_trabajo;
        	
            select *  into v_orden
            from conta.torden_trabajo 
            where id_orden_trabajo=v_parametros.id_orden_trabajo;
            
            if (pxp.f_get_variable_global('sincronizar') = 'true') then
                	                    
                    select * FROM dblink(migra.f_obtener_cadena_conexion(), 
                        'SELECT * 
                        FROM sci.f_tct_orden_trabajo_iud(' || p_id_usuario || ',''' ||
                        		pxp.f_get_variable_global('sincroniza_ip') || ''',''Sincronizacion'',''CT_ORDTRA_UPD'',NULL,' || v_parametros.id_orden_trabajo || ',' ||
                                coalesce ('''' || v_orden.desc_orden::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_orden.motivo_orden::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_orden.fecha_inicio::text || '''', 'NULL') || ',' ||
                                coalesce ('''' || v_orden.fecha_final::text || '''', 'NULL') || ',2,' ||p_id_usuario||
                                ')',TRUE)AS t1(resp varchar)
                                into v_resp; 
            end if;
               
            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Ordenes de Trabajo eliminado(a)'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_orden_trabajo',v_parametros.id_orden_trabajo::varchar);
              
            --Devuelve la respuesta
            return v_resp;

		end;
         
	else
     
    	raise exception 'Transaccion inexistente: %',p_transaccion;

	end if;

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
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;