import 'package:flutter/material.dart';

class RiwayatSiswaPage extends StatefulWidget {
  @override
  _RiwayatSiswaPageState createState() => _RiwayatSiswaPageState();
}

class _RiwayatSiswaPageState extends State<RiwayatSiswaPage> {
  String selectedFilter = 'Semua'; // Default filter
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    // Simulate data fetching
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Simulating a network call with a delay
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _isLoading = false; // Set loading to false after fetching data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: SafeArea(
        child: Stack(
          children: [
            // Background image with overlay
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/WaliRename.png'), // Ensure the image path is correct
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Dark overlay for readability
            Container(
              color: Colors.black
                  .withOpacity(0.3), // Increased opacity for better contrast
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  // Page title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0), // Add some padding
                    child: Card(
                      elevation: 8, // Shadow effect for the card
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15), // Rounded corners
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(
                            10.0), // Padding inside the card
                        decoration: BoxDecoration(
                          color:
                              Colors.blueAccent, // Background color of the card
                          borderRadius: BorderRadius.circular(
                              15), // Ensures the corners are rounded
                        ),
                        child: Text(
                          'Riwayat Presensi Siswa',
                          style: TextStyle(
                            fontSize: 26, // Increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors
                                .white, // Changed color for better visibility
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Filter buttons with cleaner layout
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Wrap(
                      spacing: 12.0, // Space between buttons horizontally
                      runSpacing: 12.0, // Space between rows of buttons
                      alignment: WrapAlignment.center,
                      children: [
                        FilterButton(
                          label: 'Semua',
                          isSelected: selectedFilter == 'Semua',
                          onTap: () {
                            setState(() {
                              selectedFilter = 'Semua';
                            });
                          },
                        ),
                        FilterButton(
                          label: 'Hadir',
                          isSelected: selectedFilter == 'Hadir',
                          onTap: () {
                            setState(() {
                              selectedFilter = 'Hadir';
                            });
                          },
                        ),
                        FilterButton(
                          label: 'Tidak Hadir',
                          isSelected: selectedFilter == 'Tidak Hadir',
                          onTap: () {
                            setState(() {
                              selectedFilter = 'Tidak Hadir';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Loading Indicator
                  if (_isLoading) Center(child: CircularProgressIndicator()),
                  if (!_isLoading)
                    // Attendance history list
                    Expanded(
                      child: ListView.builder(
                        itemCount: 10, // Number of entries
                        itemBuilder: (context, index) {
                          String status;
                          // Example logic to randomly assign statuses
                          if (index % 5 == 0) {
                            status = 'Hadir'; // 20% chance
                          } else {
                            status = 'Tidak Hadir'; // 80% chance
                          }

                          // Apply the filter logic to show only relevant records
                          if (selectedFilter != 'Semua' &&
                              selectedFilter != status) {
                            return SizedBox
                                .shrink(); // Hide entries not matching the filter
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              elevation:
                                  8, // Increased elevation for a stronger shadow effect
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    15), // More rounded corners
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Senin, 29 Maret 2024', // Example date
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Divider(color: Colors.grey),
                                      SizedBox(height: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nama Murid: Siswa ${index + 1}', // Student name example
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Kelas: 10A',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Keterangan: $status', // Status displayed
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight
                                                      .bold, // Bold for emphasis
                                                  color: status == 'Hadir'
                                                      ? Colors.green
                                                      : Colors
                                                          .redAccent, // Color for status
                                                ),
                                              ),
                                              Icon(
                                                status == 'Hadir'
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: status == 'Hadir'
                                                    ? Colors.green
                                                    : Colors.redAccent,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Button component
class FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // Shadow color
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2), // Position of the shadow
                  ),
                ]
              : [], // No shadow for unselected buttons
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
