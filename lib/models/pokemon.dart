class Pokemon {
	final String id;
	final String name;
	final String? supertype;
	final List<String> subtypes;
	final List<String> types;
	final String? hp;
	final String? rarity;
	final String? artist;
	final String? number;
	final String? setName;
	final String? setSeries;
	final String? imageSmall;
	final String? imageLarge;

	const Pokemon({
		required this.id,
		required this.name,
		this.supertype,
		this.subtypes = const [],
		this.types = const [],
		this.hp,
		this.rarity,
		this.artist,
		this.number,
		this.setName,
		this.setSeries,
		this.imageSmall,
		this.imageLarge,
	});

	factory Pokemon.fromJson(Map<String, dynamic> json) {
		final images = (json['images'] as Map<String, dynamic>?) ?? const {};
		final set = (json['set'] as Map<String, dynamic>?) ?? const {};

		return Pokemon(
			id: (json['id'] ?? '').toString(),
			name: (json['name'] ?? '').toString(),
			supertype: json['supertype']?.toString(),
			subtypes: _toStringList(json['subtypes']),
			types: _toStringList(json['types']),
			hp: json['hp']?.toString(),
			rarity: json['rarity']?.toString(),
			artist: json['artist']?.toString(),
			number: json['number']?.toString(),
			setName: set['name']?.toString(),
			setSeries: set['series']?.toString(),
			imageSmall: images['small']?.toString(),
			imageLarge: images['large']?.toString(),
		);
	}

	static List<String> _toStringList(dynamic value) {
		if (value is List) {
			return value.map((item) => item.toString()).toList();
		}
		return const [];
	}
}
