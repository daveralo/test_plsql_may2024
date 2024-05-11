create or replace package body "PACK_ITEMS" as

procedure calculate_stockvalue_per_itemloc (
    p_loc      in  number )
is    
    CURSOR C_ITEM_LOC_SOH IS
      SELECT ITEM, LOC, DEPT, UNIT_COST, STOCK_ON_HAND, UNIT_COST*STOCK_ON_HAND STOCK_VALUE
      FROM ITEM_LOC_SOH
      WHERE Loc = NVL(p_loc,Loc);

    TYPE tItem IS TABLE OF C_ITEM_LOC_SOH%ROWTYPE INDEX BY PLS_INTEGER; 
    rItem  tItem;
begin

    OPEN C_ITEM_LOC_SOH;
    LOOP FETCH C_ITEM_LOC_SOH BULK COLLECT INTO rItem;
      EXIT WHEN rItem.COUNT = 0;
      FOR X IN 1..rItem.COUNT LOOP
        INSERT INTO STOCKVALUE_PER_ITEMLOC(ITEM, LOC, DEPT, UNIT_COST, STOCK_ON_HAND, STOCK_VALUE)
        VALUES(rItem(X).ITEM, rItem(X).LOC, rItem(X).DEPT, rItem(X).UNIT_COST, rItem(X).STOCK_ON_HAND, rItem(X).STOCK_VALUE);
      END LOOP;
    END LOOP;

end calculate_stockvalue_per_itemloc;

function location_list 
return t_loc_tab PIPELINED IS
    l_loc t_loc_row;
    CURSOR C_LOC IS
      SELECT LOC, LOC_DESC
      FROM LOC;
begin
    FOR X IN C_LOC LOOP
      l_loc.LOC := X.LOC;
      l_loc.LOC_DESC := X.LOC_DESC;
      pipe row(l_loc);
    END LOOP;
    return;

end location_list;

procedure generate_files_per_location is
  v_file  UTL_FILE.FILE_TYPE;
  CURSOR C_FILES IS
    SELECT Loc
    FROM STOCKVALUE_PER_ITEMLOC
    GROUP BY Loc; 

  CURSOR C_ITEMS (pLoc NUMBER) IS 
    SELECT ITEM, DEPT, UNIT_COST, STOCK_ON_HAND, STOCK_VALUE
    FROM STOCKVALUE_PER_ITEMLOC
    WHERE Loc = pLoc;  
begin
  FOR F IN C_FILES LOOP
    v_file := UTL_FILE.FOPEN(location     => 'Utilities',
                             filename     => F.Loc||'.csv',
                             open_mode    => 'w',
                             max_linesize => 32767);
    FOR I IN C_ITEMS(F.Loc) LOOP
      UTL_FILE.PUT_LINE(v_file,I.ITEM||';'||I.DEPT||';'||I.UNIT_COST||';'||I.STOCK_ON_HAND||';'||I.STOCK_VALUE);
    END LOOP; 
    UTL_FILE.FCLOSE(v_file);
  END LOOP;
exception
  when others then
    UTL_FILE.FCLOSE(v_file);
    raise;
end generate_files_per_location;

end "PACK_ITEMS";
/