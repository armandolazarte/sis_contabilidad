--------------- SQL ---------------

CREATE OR REPLACE FUNCTION conta.f_gen_proc_plantilla_calculo (
  p_hstore_transaccion public.hstore,
  p_id_plantilla integer,
  p_monto numeric,
  p_id_usuario integer,
  p_id_depto_conta integer,
  p_id_gestion integer,
  p_proc_terci varchar = 'no'::character varying
)
RETURNS boolean AS
$body$
/**************************************************************************
 SISTEMA:		Sistema de Contabilidad
 FUNCION: 		conta.f_gen_proc_plantilla_calculo
 DESCRIPCION:   esta funcion procesa la plantilla de calculo e insertar las transacciones necesarias
 AUTOR: 		 RAC KPLIAN
 FECHA:	        04-09-2013 03:51:00
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
	v_id_transaccion	integer;
    
    v_registros record;
    v_record_int_tran    conta.tint_transaccion;
    v_record_rel_con  record;
    v_id_centro_costo_depto integer;
    v_monto_x_aplicar  numeric;
    v_monto_x_aplicar_pre  numeric;
    v_reg_id_int_transaccion integer;
    v_resp_doc boolean;
			    
BEGIN

    v_nombre_funcion = 'conta.f_gen_proc_plantilla_calculo';
  
      
     -- FOR obtener las plantillas calculos del documento(id_plantlla)
     FOR v_registros in ( 
                          SELECT  pc.id_plantilla_calculo,
                                  pc.debe_haber,
                                  pc.codigo_tipo_relacion,
                                  pc.tipo_importe,
                                  pc.importe,
                                  pc.prioridad,
                                  pc.descripcion,
                                  pc.importe_presupuesto
                          FROM  conta.tplantilla_calculo pc 
                          WHERE pc.estado_reg = 'activo' and
                                pc.id_plantilla = p_id_plantilla ) LOOP
      
        --IF es registro primario o secundario
            IF  p_proc_terci = 'si' or (v_registros.prioridad <= 2 )   THEN
        
                --  crea un record del tipo de la transaccion  
                
                v_record_int_tran = populate_record(null::conta.tint_transaccion,p_hstore_transaccion);
             
              --  obtine valor o porcentajes aplicado
               IF v_registros.tipo_importe = 'porcentaje' THEN
               
                  v_monto_x_aplicar = (p_monto * v_registros.importe)::numeric;
                  v_monto_x_aplicar_pre = (p_monto * v_registros.importe_presupuesto)::numeric;
                  
               
               ELSE
               
                  v_monto_x_aplicar = v_registros.importe::numeric;
                  v_monto_x_aplicar_pre = v_registros.importe_presupuesto::numeric;
               
               END IF;
               
               
               --  acomoda en el debe o haber 
               --  acomoda la ejecucion presupuestaria
               
               IF v_registros.debe_haber = 'debe' THEN
               
                  v_record_int_tran.importe_debe = v_monto_x_aplicar;
                  v_record_int_tran.importe_gasto =  v_monto_x_aplicar_pre;
                  v_record_int_tran.importe_haber = 0;
                  v_record_int_tran.importe_recurso = 0;
                  
               ELSE
               
                  v_record_int_tran.importe_debe = 0;
                  v_record_int_tran.importe_gasto =  0;
                  v_record_int_tran.importe_haber = v_monto_x_aplicar;
                  v_record_int_tran.importe_recurso = v_monto_x_aplicar_pre;
               
               END IF;
               
               
               -- si no es una trasaccion primaria obtener centro de costo del departamento
               
               IF v_registros.prioridad > 1 THEN
               
               -- obtener centro de consto del depto contable  CCDEPCON
              
               --  TODO , obtener replicar el centro de costo ???
                  
                  
                  raise notice ')))))))))))))) p_id_gestion = %, p_id_depto_conta = % ',p_id_gestion,p_id_depto_conta ;
                  
                  SELECT 
                      ps_id_centro_costo 
                     into 
                       v_id_centro_costo_depto 
                   FROM conta.f_get_config_relacion_contable('CCDEPCON', -- relacion contable que almacena los centros de costo por departamento
                   										     p_id_gestion, 
                                                             p_id_depto_conta, --id_tabla
                                                             NULL);  --id_dento_costo
               
                  v_record_int_tran.id_centro_costo = v_id_centro_costo_depto;
              
               END IF;
               --  aplicar relacion contable si existe
               
               
               
               
               IF  v_registros.codigo_tipo_relacion != '' and v_registros.codigo_tipo_relacion is not null THEN
               
                  
               		SELECT 
                      * 
                     into 
                       v_record_rel_con 
                    FROM conta.f_get_config_relacion_contable(v_registros.codigo_tipo_relacion, 
                   										     p_id_gestion, 
                                                             NULL, --id_tabla
                                                             v_record_int_tran.id_centro_costo);  --id_dento_costo
               
                    --replanza las cuenta, partida y auxiliar obtenidos 
                 
                     v_record_int_tran.id_cuenta = v_record_rel_con.ps_id_cuenta;
                     v_record_int_tran.id_partida = v_record_rel_con.ps_id_partida;
                     v_record_int_tran.id_auxiliar = v_record_rel_con.ps_id_auxiliar;
                    
               
               END IF;
              
               --inserta transaccion en tabla
               v_reg_id_int_transaccion = conta.f_gen_inser_transaccion(hstore(v_record_int_tran), p_id_usuario);
            
           END IF;
    
		   
        
        END LOOP;    
            return TRUE;

	
	 --Devuelve la respuesta

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