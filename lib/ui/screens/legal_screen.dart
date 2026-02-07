import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

/// Privacy policy and terms of service screen
class LegalScreen extends StatelessWidget {
  final String type; // 'privacy' or 'terms'

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        backgroundColor: GameColors.surface,
        title: Text(
          type == 'privacy' ? 'Chính sách bảo mật' : 'Điều khoản sử dụng',
          style: GameTypography.heading3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          type == 'privacy' ? _privacyPolicy : _termsOfService,
          style: GameTypography.body.copyWith(
            color: GameColors.textSecondary,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

const String _privacyPolicy = '''
CHÍNH SÁCH BẢO MẬT - ZOMBIE LIFESIM

Cập nhật lần cuối: 01/02/2026

1. THÔNG TIN THU THẬP

Zombie LifeSim thu thập rất ít thông tin cá nhân:
• Dữ liệu game (tiến trình, cài đặt) được lưu trữ cục bộ trên thiết bị
• Nếu sử dụng tính năng mua trong ứng dụng, giao dịch được xử lý qua Apple App Store hoặc Google Play Store
• Chúng tôi không thu thập tên, email, hoặc thông tin cá nhân khác

2. SỬ DỤNG DỮ LIỆU

Dữ liệu game được sử dụng duy nhất để:
• Lưu tiến trình chơi game của bạn
• Cải thiện trải nghiệm chơi game
• Xử lý giao dịch mua trong ứng dụng (nếu có)

3. CHIA SẺ DỮ LIỆU

Chúng tôi không bán, trao đổi, hoặc chia sẻ thông tin cá nhân của bạn với bên thứ ba, ngoại trừ:
• Apple/Google để xử lý giao dịch mua hàng
• Khi được yêu cầu bởi pháp luật

4. BẢO MẬT

Dữ liệu game được lưu trữ cục bộ trên thiết bị của bạn. Chúng tôi sử dụng các biện pháp bảo mật hợp lý để bảo vệ thông tin.

5. TRẺ EM

Game được đánh giá 12+. Chúng tôi không cố ý thu thập thông tin từ trẻ em dưới 13 tuổi.

6. THAY ĐỔI

Chính sách này có thể được cập nhật. Thay đổi sẽ được thông báo trong ứng dụng.

7. LIÊN HỆ

Nếu có câu hỏi về chính sách bảo mật, vui lòng liên hệ: zombielifesim@gmail.com
''';

const String _termsOfService = '''
ĐIỀU KHOẢN SỬ DỤNG - ZOMBIE LIFESIM

Cập nhật lần cuối: 01/02/2026

1. CHẤP NHẬN ĐIỀU KHOẢN

Bằng việc tải xuống và sử dụng Zombie LifeSim, bạn đồng ý với các điều khoản này.

2. GIẤY PHÉP

Chúng tôi cấp cho bạn giấy phép cá nhân, không độc quyền, không thể chuyển nhượng để sử dụng ứng dụng.

3. MUA TRONG ỨNG DỤNG

• Một số tính năng yêu cầu mua trong ứng dụng
• Tất cả giao dịch được xử lý qua Apple App Store hoặc Google Play Store
• Giao dịch không thể hoàn tiền trừ khi được quy định bởi luật pháp
• Đăng ký tự động gia hạn trừ khi bạn hủy trước ngày gia hạn

4. NỘI DUNG NGƯỜI DÙNG

• Game không cho phép người dùng tạo hoặc chia sẻ nội dung
• Tất cả nội dung game thuộc sở hữu của nhà phát triển

5. HÀNH VI CẤM

Bạn không được:
• Sao chép, sửa đổi, hoặc phân phối ứng dụng
• Kỹ thuật đảo ngược hoặc giải mã mã nguồn
• Sử dụng phần mềm gian lận hoặc hack

6. GIỚI HẠN TRÁCH NHIỆM

Ứng dụng được cung cấp "nguyên trạng" không có bảo hành. Chúng tôi không chịu trách nhiệm về bất kỳ thiệt hại nào phát sinh từ việc sử dụng ứng dụng.

7. CHẤM DỨT

Chúng tôi có quyền chấm dứt hoặc đình chỉ quyền truy cập của bạn bất kỳ lúc nào.

8. LUẬT ÁP DỤNG

Các điều khoản này được điều chỉnh bởi luật pháp Việt Nam.

9. LIÊN HỆ

zombielifesim@gmail.com
''';
