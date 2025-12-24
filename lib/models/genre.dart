class GenreData {
  final String label;
  final String imageUrl;
  final int genreId;

  GenreData({required this.label, required this.imageUrl, required this.genreId});
}

final List<GenreData> genresList = [
  GenreData(label: 'Nostalgic', imageUrl: 'https://i.ytimg.com/vi/EE1LYF_J0vE/hq720.jpg', genreId: 10751),
  GenreData(label: 'Drama', imageUrl: 'https://static0.srcdn.com/wordpress/wp-content/uploads/2023/11/matthew-mcconaughey-crying-in-interstellar.jpg', genreId: 18),
  GenreData(label: 'Romance', imageUrl: 'https://imgix.ranker.com/user_node_img/33/641410/original/641410-photo-u-1637993469', genreId: 10749),
  GenreData(label: 'Action', imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQFj82XraC_Jil95onsJTXzYZg2n-MM2mQVWg&s', genreId: 28),
  GenreData(label: 'Sci-Fi', imageUrl: 'https://variety.com/wp-content/uploads/2014/10/screen-shot-2014-10-22-at-11-36-12-am.png', genreId: 878),
  GenreData(label: 'Adventure', imageUrl: 'https://pbs.twimg.com/media/EVwIabZVcAAuXD_.jpg', genreId: 12),
  GenreData(label: 'Comedy', imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTp-IhBn3FQ0r3euLUPgq_z0yXwn_hfpLPlnA&s', genreId: 35),
  GenreData(label: 'Horror', imageUrl: 'https://www.thevintagenews.com/wp-content/uploads/sites/65/2019/02/img_9569-21-02-19-09-50-fx.jpg', genreId: 27),
];
