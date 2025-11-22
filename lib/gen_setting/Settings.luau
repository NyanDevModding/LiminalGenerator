export type gen_settings = {
	dead_end: number,
	room_amount: number?,
	access_search_depth: number?,
	-- If the generator choose the rooms that are nearby to connect
	do_choose_nearby_room: boolean?,
	-- The partition of a world to find an acces to bind to another: 1
	-- searches in the entire world and 10 takes one tenth of the world
	access_connection_proximity: number?,
}

return {
	DEAD_END_LUCK = "dead_end",
	ROOM_AMOUNT = "room_amount",
	ACCESS_SEARCH_DEPTH = "access_search_depth",
	DO_CHOOSE_NEARBY_ROOM = "do_choose_nearby_room",
	ACCESS_CONNECTION_PROXIMITY = "access_connection_proximity",
}
