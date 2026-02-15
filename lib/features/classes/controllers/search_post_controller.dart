import 'package:get/get.dart';
import '../../../data/model/post_model.dart';
import '../../../data/repository/post_repository.dart';

class SearchPostController extends GetxController {
  final PostRepository _postRepository = PostRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<PostModel> results = <PostModel>[].obs;
  final RxString keyword = ''.obs;

  int? sectionId;

  Worker? _debounceWorker;

  void init({int? sectionId}) {
    this.sectionId = sectionId;

    _debounceWorker = debounce<String>(
      keyword,
      (value) {
        _search(value);
      },
      time: const Duration(milliseconds: 500),
    );
  }

  void onKeywordChanged(String value) {
    keyword.value = value.trim();
  }

  Future<void> _search(String value) async {
  final q = value.trim();

  if (q.isEmpty) {
    results.clear();
    error.value = '';
    return;
  }

  try {
    isLoading.value = true;
    error.value = '';

    final posts = await _postRepository.searchPosts(
      sectionId: sectionId,
      keyword: q,
    );

    results.assignAll(posts);
  } catch (e) {
    error.value = 'ไม่สามารถค้นหาได้';
  } finally {
    isLoading.value = false;
  }
}

  void clear() {
    keyword.value = '';
    results.clear();
    error.value = '';
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    super.onClose();
  }
}