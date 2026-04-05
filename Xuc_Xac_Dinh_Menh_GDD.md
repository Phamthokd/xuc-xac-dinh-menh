# TÀI LIỆU GAMEPLAY CHI TIẾT
## Tên tạm: Xúc Xắc Định Mệnh
### Thể loại: Turn-based board game / Party strategy / Random event game

---

# 1. TỔNG QUAN

## 1.1. Ý tưởng cốt lõi
Người chơi điều khiển nhân vật di chuyển trên bàn cờ bằng xúc xắc.
Mỗi lần nhân vật dừng ở một ô, ô đó sẽ kích hoạt một sự kiện bất ngờ. Sự kiện có thể mang lại thưởng, phạt, vật phẩm, dịch chuyển, mất lượt hoặc ảnh hưởng tới đối thủ.

Game được xây dựng xoay quanh 3 yếu tố:
- May mắn từ xúc xắc
- Bất ngờ từ các ô sự kiện
- Chiến thuật nhẹ từ việc sử dụng vật phẩm và tận dụng tình huống

## 1.2. Trải nghiệm mong muốn
Người chơi phải cảm thấy:
- hồi hộp khi tung xúc xắc
- tò mò khi bước vào ô mới
- vui vì có các tình huống lật kèo
- dễ hiểu, dễ học, dễ chơi lại nhiều lần

Game không hướng đến chiều sâu cực nặng mà hướng đến:
- vui
- gọn
- dễ tiếp cận
- đủ chiến thuật để không quá ngẫu nhiên

# 2. MỤC TIÊU THIẾT KẾ

## 2.1. Mục tiêu của bản prototype
Bản prototype phải trả lời được 3 câu hỏi:
1. Gameplay xúc xắc + ô bất ngờ có vui không?
2. Người chơi có cảm thấy mỗi lượt đều đáng chờ không?
3. Tỉ lệ may mắn và chiến thuật có cân bằng không?

## 2.2. Nguyên tắc thiết kế
- Luật đơn giản
- Mỗi lượt ngắn
- Mỗi ô có tác động rõ ràng
- Có khả năng lật kèo
- Hạn chế quá nhiều hệ thống phụ

# 3. PHẠM VI GAME

## 3.1. Bản prototype đầu tiên
Prototype đầu chỉ tập trung vào:
- 2 người chơi
- 1 bản đồ
- 1 loại xúc xắc
- 1 hệ điểm số
- 6-8 loại ô
- 3 loại vật phẩm
- 20 lượt mỗi người

## 3.2. Chưa làm trong bản đầu
- online multiplayer
- AI nâng cao
- nhiều map
- class nhân vật
- kỹ năng riêng
- cốt truyện
- hệ chiến đấu phức tạp
- animation cầu kỳ

# 4. CẤU TRÚC TRẬN ĐẤU

## 4.1. Số người chơi
- Bản chuẩn: 2 người chơi
- Có thể mở rộng lên 3-4 sau

## 4.2. Thời lượng một trận
- Khoảng 10-20 phút
- Tùy tốc độ đọc sự kiện và thử nghiệm

## 4.3. Điều kiện thắng
Sau khi mỗi người chơi hoàn thành 20 lượt, người có điểm số cao nhất sẽ chiến thắng.

## 4.4. Điều kiện hòa
Nếu hai người bằng điểm:
1. người có nhiều vật phẩm hơn thắng
2. nếu vẫn hòa, người đứng ở vị trí xa hơn trên bàn cờ thắng
3. nếu vẫn hòa, tung xúc xắc phân định

# 5. THÀNH PHẦN GAME

## 5.1. Bàn cờ
- Có từ 24 đến 30 ô
- Các ô nối thành một đường đi cố định
- Người chơi đi theo vòng lặp quanh bàn cờ

### Vai trò của bàn cờ
- tạo cấu trúc trận đấu
- phân bố rủi ro và phần thưởng
- khiến người chơi luôn chờ mình sẽ dừng ở đâu

## 5.2. Người chơi
Mỗi người chơi có các thông tin:
- tên
- màu đại diện
- vị trí hiện tại trên bàn cờ
- điểm số
- danh sách vật phẩm
- trạng thái đặc biệt

## 5.3. Xúc xắc
- 1 xúc xắc 6 mặt
- mỗi lượt tung 1 lần
- quyết định số bước di chuyển

## 5.4. Điểm số
Điểm số là chỉ số trung tâm của trận đấu.

### Công dụng
- xác định ai đang dẫn đầu
- quyết định thắng/thua cuối trận

### Quy tắc
- người chơi bắt đầu với 0 điểm
- điểm có thể tăng hoặc giảm
- điểm không được âm
- nếu bị trừ quá số điểm hiện có, điểm về 0

## 5.5. Vật phẩm
Vật phẩm là yếu tố làm giảm cảm giác game chỉ toàn may mắn.

### Vai trò
- tăng quyền kiểm soát
- hỗ trợ lật kèo
- giúp quyết định chiến thuật

### Quy tắc
- mỗi người chơi giữ tối đa 3 vật phẩm
- nếu túi đầy mà nhận thêm vật phẩm:
  - bỏ một món cũ
  - hoặc không nhận món mới

# 6. GAMEPLAY LOOP

Mỗi trận đấu lặp lại vòng chơi này cho từng người chơi:
1. bắt đầu lượt
2. kiểm tra trạng thái đặc biệt
3. tung xúc xắc
4. di chuyển theo số bước
5. dừng ở ô cuối
6. kích hoạt sự kiện của ô
7. cập nhật điểm / vật phẩm / trạng thái
8. kết thúc lượt
9. chuyển sang người chơi tiếp theo

Loop này tiếp tục cho đến khi cả hai hoàn thành 20 lượt.

# 7. LUỒNG MỘT LƯỢT CHƠI CHI TIẾT

## 7.1. Bắt đầu lượt
Game hiển thị:
- người chơi hiện tại
- điểm hiện tại
- vật phẩm đang có
- trạng thái đặc biệt đang ảnh hưởng

### Kiểm tra trạng thái
Nếu người chơi đang bị trạng thái mất lượt:
- thông báo người chơi bị bỏ lượt
- xóa trạng thái nếu chỉ kéo dài 1 lượt
- chuyển sang người chơi tiếp theo

Nếu người chơi có buff/debuff:
- buff/debuff được áp dụng trong lượt này

## 7.2. Tung xúc xắc
Người chơi bấm nút Tung xúc xắc.
Kết quả từ 1-6 được hiển thị lên UI.

## 7.3. Di chuyển
Người chơi di chuyển đúng số ô tương ứng.

### Quy tắc di chuyển
- chỉ tính ô dừng cuối cùng
- các ô đi ngang qua không kích hoạt
- nếu đi hết ô cuối thì quay vòng về ô đầu

## 7.4. Kích hoạt ô
Khi người chơi dừng ở một ô, game:
- đọc loại ô
- hiển thị mô tả sự kiện
- áp dụng hiệu ứng

## 7.5. Cập nhật trạng thái
Sau khi kích hoạt ô:
- điểm có thể tăng/giảm
- có thể nhận vật phẩm
- có thể mất lượt sau
- có thể dịch chuyển
- có thể ảnh hưởng người chơi còn lại

## 7.6. Kết thúc lượt
- cộng số lượt đã chơi
- kiểm tra kết thúc trận chưa
- nếu chưa thì chuyển lượt

# 8. LUẬT CHƠI HOÀN CHỈNH

## 8.1. Luật di chuyển
- Mỗi lượt người chơi tung 1 xúc xắc
- Người chơi phải di chuyển đúng số bước
- Không được tự chọn số bước
- Không được bỏ qua việc di chuyển

## 8.2. Luật kích hoạt ô
- Chỉ ô cuối cùng nơi người chơi dừng lại mới được kích hoạt
- Nếu ô có hiệu ứng dịch chuyển tới ô khác:
  - ô mới vẫn được kích hoạt
- Nếu ô khiến người chơi lùi lại:
  - ở bản đầu không kích hoạt ô bị lùi tới, để giảm độ phức tạp

## 8.3. Luật điểm
- Điểm là tài nguyên chính
- Điểm không thể nhỏ hơn 0
- Mọi hiệu ứng liên quan điểm phải xử lý ngay khi sự kiện xảy ra

## 8.4. Luật vật phẩm
- Tối đa 3 vật phẩm
- Vật phẩm có thể dùng:
  - trước khi tung xúc xắc
  - hoặc trước khi kết thúc lượt, tùy loại
- Vật phẩm dùng xong sẽ biến mất

## 8.5. Luật trạng thái
Các trạng thái phổ biến:
- mất lượt
- được bảo vệ khỏi bẫy
- cộng bước di chuyển
- giảm tác hại của ô xấu

Trạng thái nên ngắn hạn, dễ hiểu, dễ hiển thị.

## 8.6. Luật va chạm người chơi
Ở prototype đầu:
- nhiều người chơi có thể đứng chung ô
- không có combat trực tiếp khi chồng ô

# 9. HỆ THỐNG Ô SỰ KIỆN

## 9.1. Ô Kho Báu
Hiệu ứng: +3 điểm
Vai trò: ô thưởng cơ bản, tạo cảm giác tiến bộ

## 9.2. Ô Bẫy Gai
Hiệu ứng: -2 điểm
Vai trò: ô phạt cơ bản, tạo rủi ro nhẹ

## 9.3. Ô Vũng Lầy
Hiệu ứng: mất lượt kế tiếp
Vai trò: phạt chiến thuật mạnh hơn mất điểm

## 9.4. Ô Cổng Dịch Chuyển
Hiệu ứng: dịch chuyển đến 1 ô ngẫu nhiên khác
Quy tắc: sau khi dịch chuyển, ô mới vẫn kích hoạt
Vai trò: tạo bất ngờ lớn, khó đoán

## 9.5. Ô Quà May Mắn
Hiệu ứng: nhận 1 vật phẩm ngẫu nhiên
Vai trò: tăng chiều sâu chiến thuật nhẹ

## 9.6. Ô Bình Yên
Hiệu ứng: không có gì xảy ra
Vai trò: giảm mật độ sự kiện, giúp nhịp game dễ thở hơn

## 9.7. Ô Cướp Điểm
Hiệu ứng: lấy 2 điểm từ đối thủ
Nếu đối thủ có ít hơn 2 điểm: lấy tối đa số điểm họ có
Vai trò: tạo cảm giác cạnh tranh trực tiếp

## 9.8. Ô Hỗn Loạn
Hiệu ứng: random một trong các kết quả:
- +3 điểm
- -3 điểm
- tiến 2 ô
- lùi 2 ô
- nhận 1 vật phẩm
Vai trò: đại diện cho tinh thần đi vào ô nào cũng có bất ngờ

# 10. HỆ THỐNG VẬT PHẨM

## 10.1. Xúc Xắc Lần Hai
Tác dụng: tung lại xúc xắc một lần
Thời điểm dùng: trước khi di chuyển
Ghi chú: phải chấp nhận kết quả mới

## 10.2. Khiên Bẫy
Tác dụng: chặn 1 hiệu ứng xấu kế tiếp
Tự động kích hoạt khi bước vào ô bất lợi

## 10.3. Giày Tăng Tốc
Tác dụng: cộng +2 bước di chuyển trong lượt hiện tại
Thời điểm dùng: trước khi tung

## 10.4. Bùa May Mắn
Tác dụng: nếu vào ô thưởng thì nhận thêm +1 điểm
Thời lượng: 1 lượt

# 11. HỆ THỐNG TRẠNG THÁI

## 11.1. Mất lượt
- người chơi bỏ qua lượt kế tiếp
- sau đó trạng thái bị xóa

## 11.2. Bảo vệ
- chặn 1 sự kiện xấu tiếp theo
- sau khi chặn xong thì biến mất

## 11.3. Tăng tốc
- cộng thêm số bước di chuyển trong lượt
- hết tác dụng ngay sau lượt

## 11.4. May mắn
- tăng phần thưởng từ ô tốt
- kéo dài 1 lượt

# 12. THIẾT KẾ CÂN BẰNG

## 12.1. Tỉ lệ ô
Trên bản đồ 24 ô, gợi ý:
- 4 ô thưởng
- 4 ô phạt
- 3 ô mất lượt / khống chế
- 3 ô vật phẩm
- 3 ô dịch chuyển
- 3 ô hỗn loạn / tương tác
- 4 ô bình yên

## 12.2. Mục tiêu cân bằng
- không để bản đồ quá nhiều ô xấu
- không để người dẫn đầu thắng quá dễ
- phải có vài cơ hội lật kèo
- nhưng không lật kèo đến mức cảm giác mọi chiến thuật vô nghĩa

## 12.3. Tần suất bất ngờ
Người chơi nên thường xuyên gặp sự kiện, nhưng không phải 100% lượt đều quá nặng.
Vì vậy cần có một số ô nghỉ như:
- ô bình yên
- ô thưởng nhỏ
- ô trung tính

# 13. NHỊP ĐỘ GAME

## Đầu trận
- người chơi làm quen luật
- sự kiện nên nhẹ
- ít phạt nặng

## Giữa trận
- bắt đầu có cướp điểm, teleport, mất lượt
- cảm giác cạnh tranh tăng dần

## Cuối trận
- quyết định thắng thua rõ rệt hơn
- các ô lật kèo bắt đầu quan trọng
- người chơi phải cân nhắc dùng vật phẩm đúng lúc

# 14. UI/UX CẦN THIẾT CHO GAMEPLAY

Người chơi phải luôn nhìn thấy:
- đang tới lượt ai
- vừa tung ra số mấy
- đang đứng ô nào
- ô đó là ô gì
- điểm hiện tại của hai người
- vật phẩm đang giữ
- còn bao nhiêu lượt

## Thông báo sự kiện
Mỗi sự kiện cần có thông báo ngắn, rõ:
- Bạn nhận 3 điểm
- Bạn mất lượt kế tiếp
- Bạn được dịch chuyển tới ô 12
- Bạn nhận vật phẩm Khiên Bẫy

# 15. CẢM GIÁC MONG MUỐN TỪ TỪNG CƠ CHẾ

## Xúc xắc
Cảm giác: hồi hộp

## Di chuyển
Cảm giác: chờ đợi kết quả

## Ô bất ngờ
Cảm giác: tò mò, bất ngờ

## Vật phẩm
Cảm giác: có quyền kiểm soát

## Cướp điểm / lật kèo
Cảm giác: gay cấn, cạnh tranh

## Kết thúc trận
Cảm giác: rõ ràng, thỏa mãn, có thể muốn chơi lại

# 16. RỦI RO THIẾT KẾ CẦN TRÁNH

## 16.1. Quá nhiều ngẫu nhiên
Nếu mọi thứ đều random:
- người chơi sẽ thấy không cần suy nghĩ
- game thành tung xúc xắc rồi chờ

### Cách xử lý
- thêm vật phẩm
- thêm vài lựa chọn chiến thuật
- giữ số lượng ô phá game ở mức vừa phải

## 16.2. Quá nhiều luật
Người mới làm game rất dễ thêm:
- quá nhiều loại ô
- quá nhiều vật phẩm
- quá nhiều trạng thái

### Cách xử lý
Prototype đầu chỉ nên có:
- 6-8 ô
- 3-4 vật phẩm
- 2-3 trạng thái

## 16.3. Nhịp game bị rối
Nếu mỗi lượt xảy ra quá nhiều thứ nối nhau:
- game khó đọc
- khó debug
- khó làm

### Cách xử lý
- mỗi ô chỉ có 1 hiệu ứng chính
- hiệu ứng phải rõ ràng
- không xâu chuỗi quá nhiều trong bản đầu

# 17. PHIÊN BẢN GAMEPLAY TỐI GIẢN ĐỀ XUẤT

Nếu cần cắt gọn để làm nhanh, dùng đúng bộ này:

## Loại ô
- Kho Báu
- Bẫy Gai
- Vũng Lầy
- Cổng Dịch Chuyển
- Quà May Mắn
- Bình Yên

## Vật phẩm
- Tung lại xúc xắc
- Khiên bẫy
- +2 bước

## Luật thắng
- 20 lượt
- ai nhiều điểm hơn thắng

Đây là bản phù hợp nhất để bạn bắt đầu bằng Godot.

# 18. ĐỊNH HƯỚNG MỞ RỘNG SAU PROTOTYPE

Sau khi bản đầu chạy ổn, có thể mở rộng bằng:
- thêm nhiều map
- thêm nhiều ô sự kiện
- thêm nhân vật có kỹ năng riêng
- thêm chế độ solo vs AI
- thêm theme fantasy / dungeon / pirate / school
- thêm mini battle thật
- thêm online multiplayer

# 19. KẾT LUẬN THIẾT KẾ

Xúc Xắc Định Mệnh là một game bàn cờ theo lượt tập trung vào:
- xúc xắc
- ô bất ngờ
- điểm số
- lật kèo vui nhộn

Bản prototype thành công khi:
- luật dễ hiểu
- chơi được từ đầu đến cuối
- mỗi lượt đều có hồi hộp
- người chơi muốn chơi thêm một ván nữa
