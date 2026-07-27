/// Authentication data models.
///
/// Maps to the backend's auth API responses.

/// User model — represents the authenticated user.
///
/// Maps to the backend's UserOut schema:
/// {id: UUID, email: str, nickname: str, created_at: datetime}
class UserModel {
  final String id;
  final String email;
  final String nickname;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        nickname: json['nickname'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Token pair returned by login/register/refresh endpoints.
///
/// Maps to the backend's TokenResponse:
/// {access_token: str, refresh_token: str, token_type: str}
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: json['token_type'] as String? ?? 'bearer',
      );
}
