import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart' as sig;
import '../../services/esignature_service.dart';
import '../../state/app_state.dart';

class ContractsPage extends StatefulWidget {
  final String projectId;

  const ContractsPage({super.key, required this.projectId});

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> with SingleTickerProviderStateMixin {
  final ESignatureService _signatureService = ESignatureService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userId = appState.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracts & E-Signatures'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Project Contracts'),
            Tab(text: 'Pending Signatures'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Project Contracts Tab
          StreamBuilder<List<Contract>>(
            stream: _signatureService.getProjectContracts(widget.projectId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No contracts',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final contracts = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: contracts.length,
                itemBuilder: (context, index) {
                  final contract = contracts[index];
                  return _ContractCard(
                    contract: contract,
                    currentUserId: userId,
                    onTap: () => _viewContract(contract, userId),
                  );
                },
              );
            },
          ),

          // Pending Signatures Tab
          StreamBuilder<List<Contract>>(
            stream: _signatureService.getPendingContracts(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No pending signatures',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final contracts = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: contracts.length,
                itemBuilder: (context, index) {
                  final contract = contracts[index];
                  return _PendingSignatureCard(
                    contract: contract,
                    onSign: () => _signContract(contract),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewContract,
        icon: const Icon(Icons.add),
        label: const Text('New Contract'),
      ),
    );
  }

  void _viewContract(Contract contract, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractDetailPage(
          contract: contract,
          currentUserId: userId,
        ),
      ),
    );
  }

  void _signContract(Contract contract) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignaturePage(contract: contract),
      ),
    );
  }

  void _createNewContract() async {
    String title = '';
    String content = '';
    final List<String> signerIds = [];

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Contract'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Contract Title',
                  hintText: 'e.g., Project Agreement',
                ),
                autofocus: true,
                onChanged: (value) => title = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Contract Content',
                  hintText: 'Enter contract terms...',
                ),
                maxLines: 5,
                onChanged: (value) => content = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Signer IDs (comma-separated)',
                  hintText: 'user1,user2,user3',
                ),
                onChanged: (value) {
                  signerIds.clear();
                  signerIds.addAll(value.split(',').map((e) => e.trim()));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true && title.isNotEmpty && content.isNotEmpty) {
      await _signatureService.createContract(
        projectId: widget.projectId,
        title: title,
        content: content,
        signerIds: signerIds,
      );
    }
  }
}

class _ContractCard extends StatelessWidget {
  final Contract contract;
  final String currentUserId;
  final VoidCallback onTap;

  const _ContractCard({
    required this.contract,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSigned = contract.signatures.containsKey(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contract.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusBadge(status: contract.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                contract.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    hasSigned ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: hasSigned ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasSigned ? 'You signed' : 'Awaiting your signature',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasSigned ? Colors.green : Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${contract.signatures.length}/${contract.signerIds.length} signed',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: contract.signatureProgress,
                backgroundColor: Colors.grey[200],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingSignatureCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback onSign;

  const _PendingSignatureCard({
    required this.contract,
    required this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange[50],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contract.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              contract.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onSign,
              icon: const Icon(Icons.edit),
              label: const Text('Sign Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40) as Size?,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ContractStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case ContractStatus.draft:
        color = Colors.grey;
        text = 'DRAFT';
        break;
      case ContractStatus.pending:
        color = Colors.orange;
        text = 'PENDING';
        break;
      case ContractStatus.completed:
        color = Colors.green;
        text = 'COMPLETED';
        break;
      case ContractStatus.voided:
        color = Colors.red;
        text = 'VOIDED';
        break;
      case ContractStatus.expired:
        color = Colors.grey;
        text = 'EXPIRED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Contract Detail Page
class ContractDetailPage extends StatelessWidget {
  final Contract contract;
  final String currentUserId;

  const ContractDetailPage({
    super.key,
    required this.contract,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final hasSigned = contract.signatures.containsKey(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contract.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _StatusBadge(status: contract.status),
            const SizedBox(height: 24),
            const Text(
              'Contract Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(contract.content),
            const SizedBox(height: 24),
            const Text(
              'Signatures',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...contract.signerIds.map((signerId) {
              final signature = contract.signatures[signerId];
              return Card(
                child: ListTile(
                  leading: Icon(
                    signature != null ? Icons.check_circle : Icons.pending,
                    color: signature != null ? Colors.green : Colors.grey,
                  ),
                  title: Text('User $signerId'),
                  subtitle: signature != null
                      ? Text('Signed on ${signature.signedAt.month}/${signature.signedAt.day}/${signature.signedAt.year}')
                      : const Text('Not signed yet'),
                  trailing: signature != null
                      ? Image.network(
                          signature.signatureUrl,
                          width: 100,
                          height: 50,
                          fit: BoxFit.contain,
                        )
                      : null,
                ),
              );
            }),
            const SizedBox(height: 24),
            if (!hasSigned && contract.signerIds.contains(currentUserId))
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignaturePage(contract: contract),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Sign Contract'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48) as Size?,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Signature Page
class SignaturePage extends StatefulWidget {
  final Contract contract;

  const SignaturePage({super.key, required this.contract});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final sig.SignatureController _controller = sig.SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a signature')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final signatureImage = await _controller.toPngBytes();
      if (signatureImage == null) {
        throw Exception('Failed to capture signature');
      }

      final signatureService = ESignatureService();
      await signatureService.signContract(
        contractId: widget.contract.id,
        signatureImage: signatureImage,
        signedName: _nameController.text.isEmpty ? null : _nameController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contract signed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Contract'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _controller.clear,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contract.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.contract.content),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign Here',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: sig.Signature(
              controller: _controller,
              backgroundColor: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _controller.clear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSignature,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign & Submit'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
