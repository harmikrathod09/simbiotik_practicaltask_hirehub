import 'package:flutter/material.dart';

class JobModel {
  // Raw API Fields
  final String slug;
  final String companyName;
  final bool remote;
  final String url;
  final List<String> tags;
  final List<String> jobTypes;
  final int createdAt;
  final String rawDescription;

  // Processed UI Fields
  final String id;
  final String title;
  final String company;
  final IconData companyLogo;
  final String location;
  final String salary;
  final String timeType;
  final String experienceLevel;
  final String description;
  final List<String> requirements;
  final List<String> benefits;
  final String datePosted;
  bool isBookmarked;

  JobModel({
    required this.slug,
    required this.companyName,
    required this.remote,
    required this.url,
    required this.tags,
    required this.jobTypes,
    required this.createdAt,
    required this.rawDescription,

    required this.id,
    required this.title,
    required this.company,
    required this.companyLogo,
    required this.location,
    required this.salary,
    required this.timeType,
    required this.experienceLevel,
    required this.description,
    required this.requirements,
    required this.benefits,
    required this.datePosted,
    this.isBookmarked = false,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] ?? 'Unknown Position';
    final company = json['company_name'] ?? 'Unknown Company';
    final rawLocation = json['location'] ?? 'Bengaluru, India';
    final isRemote = json['remote'] ?? false;
    final rawDesc = json['description'] ?? '';

    String stripHtml(String html) {
      return html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    String extractParagraphs(String html) {
      var matches = RegExp(r'<p>(.*?)</p>', dotAll: true).allMatches(html);
      if (matches.isEmpty) {
        return stripHtml(html);
      }
      return matches.map((m) => stripHtml(m.group(1) ?? '')).join('\n\n');
    }

    List<String> extractListItems(String html) {
      List<String> items = [];
      var matches = RegExp(r'<li>(.*?)</li>', dotAll: true).allMatches(html);
      for (var match in matches) {
        items.add(stripHtml(match.group(1) ?? ''));
      }
      return items;
    }

    String cleanDesc = extractParagraphs(rawDesc);
    if (cleanDesc.isEmpty) {
      cleanDesc = stripHtml(rawDesc);
    }
    // No truncation: keep full cleaned description
    // if (cleanDesc.length > 800) {
    //   cleanDesc = '${cleanDesc.substring(0, 800)}...';
    // }
    if (cleanDesc.isEmpty) {
      cleanDesc = 'No description provided for this job.';
    }

    final listItems = extractListItems(rawDesc);
    List<String> requirements = [];
    List<String> benefits = [];

    if (listItems.isNotEmpty) {
      int splitIndex = listItems.length > 5 ? listItems.length ~/ 2 : listItems.length;
      requirements = listItems.sublist(0, splitIndex);
      benefits = listItems.sublist(splitIndex);
    } else {
      final tagsList = List<String>.from(json['tags'] ?? []);
      requirements = tagsList.isNotEmpty ? tagsList : ['See full description for details'];
      benefits = ['Apply to learn about the benefits'];
    }

    final code = company.hashCode.abs();
    
    final location = rawLocation;

    // Mapped salaries to Lakhs Per Annum (LPA) in Indian Rupees (₹)
    final salaryMin = 6 + (code % 12); // ₹6L - ₹17L
    final salaryMax = salaryMin + 4 + (code % 15); // ₹10L - ₹36L
    final salaryStr = '₹${salaryMin}L - ₹${salaryMax}L LPA';

    IconData companyIcon;
    switch (code % 5) {
      case 0:
        companyIcon = Icons.code;
        break;
      case 1:
        companyIcon = Icons.insights;
        break;
      case 2:
        companyIcon = Icons.palette;
        break;
      case 3:
        companyIcon = Icons.settings;
        break;
      default:
        companyIcon = Icons.business;
        break;
    }

    String level = 'Mid-level';
    if (title.toLowerCase().contains('senior') ||
        title.toLowerCase().contains('lead') ||
        title.toLowerCase().contains('principal')) {
      level = 'Senior';
    } else if (title.toLowerCase().contains('junior') ||
        title.toLowerCase().contains('intern') ||
        title.toLowerCase().contains('werkstudent')) {
      level = 'Junior';
    } else if (title.toLowerCase().contains('manager') ||
        title.toLowerCase().contains('head') ||
        title.toLowerCase().contains('director')) {
      level = 'Lead / Manager';
    }

    int? createdAt = json['created_at'];
    String datePosted = '${(code % 14) + 1}d ago'; // fallback
    if (createdAt != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) {
        datePosted = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        datePosted = '${diff.inHours}h ago';
      } else {
        datePosted = 'Just now';
      }
    }

    return JobModel(
      slug: json['slug'] ?? '',
      companyName: company,
      remote: isRemote,
      url: json['url'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      jobTypes: List<String>.from(json['job_types'] ?? []),
      createdAt: createdAt ?? 0,
      rawDescription: rawDesc,

      id: json['slug'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      company: company,
      companyLogo: companyIcon,
      location: location,
      salary: salaryStr,
      timeType: isRemote ? 'Remote' : 'On-site',
      experienceLevel: level,
      description: cleanDesc,
      requirements: requirements,
      benefits: benefits,
      datePosted: datePosted,
    );
  }

  JobModel copyWith({
    String? slug,
    String? companyName,
    bool? remote,
    String? url,
    List<String>? tags,
    List<String>? jobTypes,
    int? createdAt,
    String? rawDescription,

    String? id,
    String? title,
    String? company,
    IconData? companyLogo,
    String? location,
    String? salary,
    String? timeType,
    String? experienceLevel,
    String? description,
    List<String>? requirements,
    List<String>? benefits,
    String? datePosted,
    bool? isBookmarked,
  }) {
    return JobModel(
      slug: slug ?? this.slug,
      companyName: companyName ?? this.companyName,
      remote: remote ?? this.remote,
      url: url ?? this.url,
      tags: tags ?? this.tags,
      jobTypes: jobTypes ?? this.jobTypes,
      createdAt: createdAt ?? this.createdAt,
      rawDescription: rawDescription ?? this.rawDescription,

      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      companyLogo: companyLogo ?? this.companyLogo,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      timeType: timeType ?? this.timeType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      datePosted: datePosted ?? this.datePosted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
