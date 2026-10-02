import 'package:flutter_test/flutter_test.dart';
import 'package:sinvo/main.dart';

void main(){
  testWidgets('SINVO app boots',(tester)async{
    await tester.pumpWidget(const SinvoApp());
    expect(find.text('Dashboard'),findsOneWidget);
  });
}
