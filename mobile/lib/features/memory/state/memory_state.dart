import '../models/memory_model.dart';

/// UI state for the memory feature.
class MemoryState {
  /// All loaded memories (both approved and pending).
  final List<MemoryModel> memories;

  /// Count of approved memories.
  final int approvedCount;

  /// Count of pending (not yet approved) memories.
  final int pendingCount;

  /// Whether memories are being loaded.
  final bool isLoading;

  /// Whether an action (approve/edit/delete/add) is in progress.
  final bool isProcessing;

  /// Error message, if any.
  final String? errorMessage;

  const MemoryState({
    this.memories = const [],
    this.approvedCount = 0,
    this.pendingCount = 0,
    this.isLoading = false,
    this.isProcessing = false,
    this.errorMessage,
  });

  static const MemoryState initial = MemoryState();

  /// Get pending (unapproved) memories.
  List<MemoryModel> get pendingMemories =>
      memories.where((m) => !m.approved).toList();

  /// Get approved memories.
  List<MemoryModel> get approvedMemories =>
      memories.where((m) => m.approved).toList();

  /// Whether there are pending memories needing review.
  bool get hasPending => pendingCount > 0;

  MemoryState copyWith({
    List<MemoryModel>? memories,
    int? approvedCount,
    int? pendingCount,
    bool? isLoading,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MemoryState(
      memories: memories ?? this.memories,
      approvedCount: approvedCount ?? this.approvedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
