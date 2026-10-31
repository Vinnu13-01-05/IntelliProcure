CLASS lsc_zi_req DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PUBLIC SECTION.
    CLASS-DATA gt_decisions TYPE STANDARD TABLE OF zint_decision WITH EMPTY KEY.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_req IMPLEMENTATION.
  METHOD save_modified.
    IF gt_decisions IS NOT INITIAL.
      MODIFY zint_decision FROM TABLE @gt_decisions.
      CLEAR gt_decisions.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_ZI_REQ DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR zi_req RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR zi_req RESULT result.

    METHODS simulate_alternatives FOR MODIFY
      keys FOR ACTION zi_req~simulate_alternatives RESULT result.

ENDCLASS.


CLASS lhc_ZI_REQ IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.


  METHOD get_global_authorizations.
  ENDMETHOD.


  METHOD simulate_alternatives.

    DATA lv_requested     TYPE i.
    DATA lv_internal      TYPE i.
    DATA lv_repair        TYPE i.
    DATA lv_purchase      TYPE i.
    DATA lv_remaining     TYPE i.
    DATA lv_repair_count  TYPE i.
    DATA lv_reason        TYPE string.
    DATA lv_action        TYPE c LENGTH 30.
    DATA lv_unit_cost     TYPE p DECIMALS 2.
    DATA lv_repair_cost   TYPE p DECIMALS 2.
    DATA lv_est_cost      TYPE p DECIMALS 2.
    DATA lv_est_saving    TYPE p DECIMALS 2.
    DATA lv_decision_id   TYPE c LENGTH 18.

    READ ENTITIES OF zi_req IN LOCAL MODE
      ENTITY zi_req
      FIELDS ( request_id resource_id quantity )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    LOOP AT lt_requests INTO DATA(ls_request).

      CLEAR:
        lv_requested,
        lv_internal,
        lv_repair,
        lv_purchase,
        lv_remaining,
        lv_repair_count,
        lv_reason,
        lv_action,
        lv_est_cost,
        lv_est_saving.

      lv_requested = ls_request-quantity.

      " Benchmark unit cost and repair cost
      CASE ls_request-resource_id.
        WHEN 'LAPTOP'.
          lv_unit_cost   = 1000.
          lv_repair_cost = 150.
        WHEN 'MONITOR'.
          lv_unit_cost   = 250.
          lv_repair_cost = 50.
        WHEN OTHERS.
          lv_unit_cost   = 500.
          lv_repair_cost = 100.
      ENDCASE.

      "--------------------------------------------------
      " 1. Check internally available resources by CATEGORY
      "--------------------------------------------------
      SELECT SUM( quantity )
        FROM zint_resource
        WHERE ( category = @ls_request-resource_id OR resource_id = @ls_request-resource_id )
          AND availability = 'AVAILABLE'
        INTO @lv_internal.

      IF lv_internal > lv_requested.
        lv_internal = lv_requested.
      ENDIF.

      lv_remaining = lv_requested - lv_internal.

      "--------------------------------------------------
      " 2. Check repair candidates (matches PENDING and OPEN)
      "--------------------------------------------------
      IF lv_remaining > 0.

        SELECT COUNT( * )
          FROM zint_repair
          WHERE ( resource_id = @ls_request-resource_id
               OR resource_id IN ( SELECT resource_id FROM zint_resource WHERE category = @ls_request-resource_id ) )
            AND ( repair_status = 'PENDING' OR repair_status = 'OPEN' OR repair_status IS INITIAL )
          INTO @lv_repair_count.

        " Also check ZINT_RESOURCE damaged/repair candidates
        IF lv_repair_count = 0.
          SELECT SUM( quantity )
            FROM zint_resource
            WHERE ( category = @ls_request-resource_id OR resource_id = @ls_request-resource_id )
              AND ( availability = 'REPAIR' OR repair_required = 'X' )
            INTO @lv_repair_count.
        ENDIF.

        IF lv_repair_count > lv_remaining.
          lv_repair = lv_remaining.
        ELSE.
          lv_repair = lv_repair_count.
        ENDIF.

        lv_remaining = lv_remaining - lv_repair.

      ENDIF.

      "--------------------------------------------------
      " 3. Remaining quantity must be purchased externally
      "--------------------------------------------------
      lv_purchase = lv_remaining.

      "--------------------------------------------------
      " 4. Cost and Savings calculation (Task 4)
      "--------------------------------------------------
      lv_est_cost   = ( lv_purchase * lv_unit_cost ) + ( lv_repair * lv_repair_cost ).
      lv_est_saving = ( lv_requested * lv_unit_cost ) - lv_est_cost.

      "--------------------------------------------------
      " 5. Determine Recommended Action & Description
      "--------------------------------------------------
      IF lv_purchase = 0 AND lv_repair = 0.
        lv_action = 'INTERNAL REUSE'.
        lv_reason = |Internal Reuse: { lv_internal }. Saved: ${ lv_est_saving } (100% saved)|.

      ELSEIF lv_purchase = 0.
        lv_action = 'REUSE AND REPAIR'.
        lv_reason = |Reuse: { lv_internal }, Repair: { lv_repair }. Cost: ${ lv_est_cost }, Saved: ${ lv_est_saving }|.

      ELSEIF lv_internal > 0 OR lv_repair > 0.
        lv_action = 'HYBRID PROCUREMENT'.
        lv_reason = |Reuse: { lv_internal }, Repair: { lv_repair }, Purchase: { lv_purchase }. Cost: ${ lv_est_cost }, Saved: ${ lv_est_saving }|.

      ELSE.
        lv_action = 'EXTERNAL PURCHASE'.
        lv_reason = |Purchase { lv_purchase } units externally. Estimated Cost: ${ lv_est_cost }|.
      ENDIF.

      "--------------------------------------------------
      " 6. Buffer Decision Record for Additional Save (Task 2)
      "--------------------------------------------------
      lv_decision_id = |DEC-{ ls_request-request_id+3(13) }|.

      APPEND VALUE #(
        client             = sy-mandt
        decision_id        = lv_decision_id
        request_id         = ls_request-request_id
        requested_quantity = lv_requested
        internal_quantity  = lv_internal
        repair_quantity    = lv_repair
        purchase_quantity  = lv_purchase
        recommended_action = lv_action
        estimated_cost     = lv_est_cost
        estimated_saving   = lv_est_saving
        decision_status    = 'SIMULATED'
        decision_reason    = lv_reason
      ) TO lsc_zi_req=>gt_decisions.

      "--------------------------------------------------
      " 7. Update the purchase request
      "--------------------------------------------------
      MODIFY ENTITIES OF zi_req IN LOCAL MODE
        ENTITY zi_req
        UPDATE FIELDS ( status reason )
        WITH VALUE #(
          ( %tky   = ls_request-%tky
            status = 'SIMULATED'
            reason = lv_reason )
        )
        FAILED failed
        REPORTED reported.

      "--------------------------------------------------
      " 8. Return updated row & display UI notification
      "--------------------------------------------------
      READ ENTITIES OF zi_req IN LOCAL MODE
        ENTITY zi_req
        ALL FIELDS
        WITH VALUE #( ( %tky = ls_request-%tky ) )
        RESULT DATA(lt_updated_request).

      IF lt_updated_request IS NOT INITIAL.
        APPEND VALUE #(
          %tky   = ls_request-%tky
          %param = CORRESPONDING #( lt_updated_request[ 1 ] )
        ) TO result.

        APPEND VALUE #(
          %tky = ls_request-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-success
                   text     = lv_reason
                 )
        ) TO reported-zi_req.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
