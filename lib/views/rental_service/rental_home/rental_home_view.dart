import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../consts/appConst.dart';
import '../car_rental/car_rental_view.dart';

class RentalHomeView extends StatefulWidget {
  const RentalHomeView({super.key});

  @override
  State<RentalHomeView> createState() => _RentalHomeViewState();
}

class _RentalHomeViewState extends State<RentalHomeView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedType = 'All';

  final List<_RentalOption> _items = const [
    _RentalOption(type: 'Car', title: 'Toyota Camry', subtitle: 'Economy sedan • 5 seats', price: r'$42/day', distance: '1.4 mi', icon: Icons.directions_car_filled_outlined),
    _RentalOption(type: 'Car', title: 'Honda CR-V', subtitle: 'SUV • luggage friendly', price: r'$58/day', distance: '2.1 mi', icon: Icons.airport_shuttle_outlined),
    _RentalOption(type: 'XL', title: 'Dodge Grand Caravan', subtitle: 'XL van • family trips', price: r'$72/day', distance: '3.0 mi', icon: Icons.directions_bus_filled_outlined),
    _RentalOption(type: 'Apartment', title: 'Short stay apartment', subtitle: 'Studio • verified host', price: r'$89/night', distance: '2.8 mi', icon: Icons.apartment_rounded),
    _RentalOption(type: 'House', title: 'Family house rental', subtitle: '3 bedrooms • driveway', price: r'$135/night', distance: '4.2 mi', icon: Icons.home_work_outlined),
  ];

  List<_RentalOption> get _visibleItems {
    final q = _query.trim().toLowerCase();
    return _items.where((item) {
      final typeOk = _selectedType == 'All' || item.type == _selectedType;
      final searchOk = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q) ||
          item.type.toLowerCase().contains(q);
      return typeOk && searchOk;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openItem(_RentalOption item) {
    Get.to(
      () => CarRentalView(
        title: item.title,
        description: '${item.subtitle}\n${item.price} • ${item.distance} away',
        category: item.type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _searchBar(),
                SizedBox(height: 16.h),
                _filters(),
                SizedBox(height: 20.h),
                _sectionTitle(),
                SizedBox(height: 12.h),
                for (final item in _visibleItems) ...[
                  _rentalCard(item),
                  SizedBox(height: 10.h),
                ],
                if (_visibleItems.isEmpty) _emptyState(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        color: AppConst.black,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 24.h),
          child: Row(
            children: [
              IconButton(
                onPressed: Get.back,
                icon: Icon(Icons.arrow_back_rounded, color: AppConst.white, size: 26.sp),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rental', style: TextStyle(color: AppConst.white, fontSize: 24.sp, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3.h),
                    Text('Cars, apartments and homes near you', style: TextStyle(color: AppConst.white.withValues(alpha: 0.72), fontSize: 12.sp)),
                  ],
                ),
              ),
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(color: AppConst.primaryColor, borderRadius: BorderRadius.circular(16.r)),
                child: Icon(Icons.map_outlined, color: AppConst.black, size: 22.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Material(
      color: AppConst.white,
      borderRadius: BorderRadius.circular(20.r),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search cars, apartments, houses',
          prefixIcon: const Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
    );
  }

  Widget _filters() {
    final filters = ['All', 'Car', 'XL', 'Apartment', 'House'];
    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, index) {
          final f = filters[index];
          final selected = f == _selectedType;
          return ChoiceChip(
            selected: selected,
            label: Text(f),
            onSelected: (_) => setState(() => _selectedType = f),
            selectedColor: AppConst.primaryColor,
            backgroundColor: AppConst.white,
            labelStyle: TextStyle(color: AppConst.black, fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r), side: BorderSide.none),
          );
        },
      ),
    );
  }

  Widget _sectionTitle() {
    return Row(
      children: [
        Expanded(child: Text('Nearby rental options', style: TextStyle(color: AppConst.black, fontSize: 19.sp, fontWeight: FontWeight.w900))),
        Text('${_visibleItems.length} available', style: TextStyle(color: AppConst.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _rentalCard(_RentalOption item) {
    return Material(
      color: AppConst.white,
      borderRadius: BorderRadius.circular(22.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openItem(item),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 62.w,
                height: 62.w,
                decoration: BoxDecoration(color: AppConst.primaryColor.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(20.r)),
                child: Icon(item.icon, color: AppConst.black, size: 30.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(color: AppConst.black, fontSize: 15.sp, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4.h),
                    Text(item.subtitle, style: TextStyle(color: AppConst.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 7.h),
                    Row(children: [
                      Icon(Icons.near_me_outlined, color: AppConst.textSecondary, size: 15.sp),
                      SizedBox(width: 4.w),
                      Text(item.distance, style: TextStyle(color: AppConst.textSecondary, fontSize: 11.sp, fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.price, style: TextStyle(color: AppConst.black, fontSize: 14.sp, fontWeight: FontWeight.w900)),
                  SizedBox(height: 16.h),
                  Icon(Icons.chevron_right_rounded, color: AppConst.textSecondary, size: 26.sp),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48.sp, color: AppConst.textSecondary),
          SizedBox(height: 10.h),
          Text('No rental option found', style: TextStyle(color: AppConst.black, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RentalOption {
  const _RentalOption({required this.type, required this.title, required this.subtitle, required this.price, required this.distance, required this.icon});
  final String type;
  final String title;
  final String subtitle;
  final String price;
  final String distance;
  final IconData icon;
}
