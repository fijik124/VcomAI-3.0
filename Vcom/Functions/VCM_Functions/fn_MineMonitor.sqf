/* Author: Genesis. Native mines handle triggering; this registry only needs pruning. */
VCOM_MINEARRAY = VCOM_MINEARRAY select {!isNull (_x select 0) && {alive (_x select 0)}};
