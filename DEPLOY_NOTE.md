# Deploy Note - Caro Game

Dưới đây là thông tin chi tiết về việc cấu hình tự động deploy game Caro Flutter Web lên GitHub Pages:

### 🔗 Link chạy game online
*   **Link ứng dụng:** **[https://ptcutis1tg.github.io/caro/](https://ptcutis1tg.github.io/caro/)**

---

### 📂 Các file đã tạo / chỉnh sửa trong dự án:
1.  **`.github/workflows/deploy.yml`** (Tạo mới): File cấu hình GitHub Actions. Mỗi khi bạn `push` code lên nhánh `main`, hệ thống sẽ tự động build bản Web và deploy lên GitHub Pages.
2.  **`DEPLOY_NOTE.md`** (Tạo mới): Chính là file tài liệu hướng dẫn này.
3.  **`lib/screens/login_screen.dart`** (Chỉnh sửa): Đã sửa lỗi crash màn hình đỏ khi gửi email quên mật khẩu.

---

### 💻 Các lệnh GitHub CLI (`gh`) và Git đã thực hiện:
*   **Chuyển chế độ repo sang Public**:
    `gh repo edit --visibility public --accept-visibility-change-consequences`
    *(Vì gói GitHub Free không hỗ trợ GitHub Pages cho kho lưu trữ Private nên chúng ta cần chuyển repo sang Public để chạy được online).*
*   **Bật tính năng GitHub Pages qua Actions**:
    `gh api repos/ptcutis1tg/caro/pages -f build_type=workflow`
*   **Commit và Push code**:
    `git add .`
    `git commit -m "Fix forgot password dialog crash and add GitHub Pages deploy workflow"`
    `git push origin main`

---

### 🔐 Hướng dẫn thêm cấu hình Secret (Tùy chọn):
Hiện tại ứng dụng đang tự động lấy thông tin Supabase mặc định có sẵn trong mã nguồn. Nếu bạn muốn thay đổi URL hoặc Key Supabase khác một cách an toàn mà không cần sửa code, bạn có thể:
1.  Truy cập vào Repository của bạn trên GitHub Web: **[https://github.com/ptcutis1tg/caro](https://github.com/ptcutis1tg/caro)**
2.  Đi tới **Settings** > **Secrets and variables** > **Actions**.
3.  Chọn **New repository secret** và thêm 2 khóa sau:
    *   `SUPABASE_URL`: URL Supabase của bạn.
    *   `SUPABASE_PUBLISHABLE_KEY`: Key publishable/anon của bạn.
4.  Khi có thay đổi về code hoặc cấu hình này, GitHub Actions sẽ tự động biên dịch lại cùng với các biến môi trường mới của bạn.
