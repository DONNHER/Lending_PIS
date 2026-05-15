import 'loan.dart'; 

class CoMaker {
  final int? id;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String relationshipToBorrower;
  final DateTime? createdAt;
  
  // Relationship: Equivalent to $this->hasMany(Loan::class)
  final List<Loan>? loans;

  CoMaker({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.relationshipToBorrower,
    this.createdAt,
    this.loans,
  });

  /// The "Eloquent Hydrator": Converts Supabase Map to CoMaker Object
  factory CoMaker.fromMap(Map<String, dynamic> map) {
    return CoMaker(
      id: map['id'],
      fullName: map['full_name'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      address: map['address'] ?? '',
      relationshipToBorrower: map['relationship_to_borrower'] ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      
      // Mapping the HasMany relationship
      loans: map['loans'] != null
          ? (map['loans'] as List)
              .map((loanItem) => Loan.fromMap(loanItem))
              .toList()
          : null,
    );
  }

  /// Equivalent to $model->toArray() or $model->toJson()
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address': address,
      'relationship_to_borrower': relationshipToBorrower,
    };
  }
}