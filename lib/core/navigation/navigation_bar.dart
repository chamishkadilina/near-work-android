import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/explore/screens/explore_page.dart';
import 'package:nearwork/features/messages/screens/messages_page.dart';
import 'package:nearwork/features/post_job/screens/post_job_page.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/profile/screens/profile_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;

  final GlobalKey<ExplorePageState> _exploreKey = GlobalKey<ExplorePageState>();

  void _viewJobOnExplore(Job job) {
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _exploreKey.currentState?.showJobSheet(job);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ExplorePage(key: _exploreKey),
          const MessagesPage(),
          PostJobPage(onViewOnMap: _viewJobOnExplore),
          ProfilePage(onViewOnMap: _viewJobOnExplore),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.background,
        iconSize: 28,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_rounded),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'Post Job',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
