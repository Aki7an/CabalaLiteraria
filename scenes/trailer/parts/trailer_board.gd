extends Control

func cells() -> Array:
	var found: Array = []
	for child in get_children():
		if child.has_method("show_letter"):
			found.append(child)
	return found


func cells_for(letter: String) -> Array:
	var found: Array = []
	for cell in cells():
		if bool(cell.get("is_space")) or bool(cell.get("is_fixed")):
			continue
		if str(cell.get("cipher_letter")) == letter:
			found.append(cell)
	return found


func cells_spelling(word: String) -> Array:
	var letters: Array = []
	for cell in cells():
		if bool(cell.get("is_space")):
			continue
		letters.append(cell)
	var target := word.to_upper()
	if target.is_empty() or letters.size() < target.length():
		return []
	for i in range(letters.size() - target.length() + 1):
		var matched := true
		for j in target.length():
			if str(letters[i + j].get("cipher_letter")) != target.substr(j, 1):
				matched = false
				break
		if matched:
			var found: Array = []
			for j in target.length():
				found.append(letters[i + j])
			return found
	return []


func first_cell(letter: String) -> Control:
	var found := cells_for(letter)
	return found[0] if not found.is_empty() else null


func apply_start_letters(letters: String) -> void:
	for cell in cells():
		if bool(cell.get("is_fixed")):
			continue
		var ch := str(cell.get("cipher_letter"))
		if letters.find(ch) >= 0 and not bool(cell.get("is_space")):
			cell.start_letter = ch
			cell.show_letter(ch, Color(0.18, 0.12, 0.08, 1), Color(0.78, 0.76, 0.74, 1))
		else:
			cell.start_letter = ""
			if cell.has_method("clear_letter"):
				cell.clear_letter()
