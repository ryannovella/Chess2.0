extends SceneTree
func _init():
    var menu = load("res://src/ui/menu/main_menu.tscn").instantiate()
    root.add_child(menu)
    menu._setup_settings_form()
    print("ChkWhiteEngine text: ", menu.chk_white_engine.text)
    print("ChkWhiteThreats text: ", menu.chk_white_threats.text)
    print("ChkBlackEngine text: ", menu.chk_black_engine.text)
    print("ChkBlackThreats text: ", menu.chk_black_threats.text)
    for i in range(menu.opt_piece_set.item_count):
        print("Piece set [", i, "]: ", menu.opt_piece_set.get_item_text(i))
    for i in range(menu.opt_board_theme.item_count):
        print("Board theme [", i, "]: ", menu.opt_board_theme.get_item_text(i))
    menu.free()
    quit()
