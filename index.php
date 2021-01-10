<?php
require 'config.php';

?>

<!DOCTYPE html>
<html lane="en">
	<head>
		<meta charset="utf-8">
		<title>HOME</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-giJF6kkoqNQ00vy+HMDP7azOuL0xtbfIcaT9wjKHr8RbDVddVHyTfAAsrekwKmP1" crossorigin="anonymous">
	</head>
	<body>
		<?php
			$pdostatement = $pdo->prepare("SELECT * FROM todo ORDER BY id DESC");
			$pdostatement->execute();
			$result = $pdostatement->fetchAll();
		?>
		<div class="card">
			<div class="card-body">
				<h2>Todo Project</h2>
				<div>
					<a href="add.php" type="button" class="btn btn-success">Create</a>
				</div><br>
				<table class="table table-striped">
					<thead>
						<tr>
							<th>ID</th>
							<th>Title</th>
							<th>Description</th>
							<th>Created</th>
							<th>Actions</th>						
						</tr>
					</thead>
					<tbody>
					<?php
					$i = 1;
					if($result) {
						foreach ($result as $value) {
					?>
						<tr>
							 <td><?php echo $i; ?></td>
							 <td><?php echo $value['title'] ?></td>
							 <td><?php echo $value['description'] ?></td>
							 <td><?php echo date('Y-m-d',strtotime($value['created_at'])) ?></td>
							 <td>
								<a type="button" class="btn btn-warning" href="edit.php?id=<?php echo $value['id']; ?>">Edit</a>
								<a type="button" class="btn btn-danger" href="delete.php?id=<?php echo $value['id']; ?>">Delete</a>		
							 </td>
						</tr>
					<?php
					 	$i++;
						}
					}
					?>						
					</tbody>					
				</table>
			</div>			
		</div>
	</body>
</html>