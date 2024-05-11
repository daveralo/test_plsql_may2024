create or replace package "PACK_ITEMS" as

--==============================================================================
-- Procedure that can be invoked by store or all stores to save the item_loc_soh to a new table that will contain the same information plus the stock value per item/loc (unit_cost*stock_on_hand)
--==============================================================================
procedure calculate_stockvalue_per_itemloc (
    p_loc      in  number);

--==============================================================================
-- Pipeline function to be used in the location list of values
--==============================================================================

-- Record Type used to define columns for the pipelined output.
TYPE t_loc_row IS RECORD
(LOC  NUMBER(10,0), 
 LOC_DESC VARCHAR2(25) );

-- Table type used to define the table output.
TYPE t_loc_tab IS TABLE OF t_loc_row;

function location_list
return t_loc_tab PIPELINED;

--==============================================================================
-- Procedure that can extract to a flat file (csv), 1 file per location
--==============================================================================

procedure generate_files_per_location;

end "PACK_ITEMS";
/