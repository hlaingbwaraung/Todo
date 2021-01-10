<?php
require 'config.php';
if (!empty($_POST)){
    $title=$_POST['title'];
    $desc=$_POST['description'];

    $sql ="INSERT INTO todo(title,description) VALUES(:title,:description)";
    $pdostatement= $pdo->prepare($sql);
    $result=$pdostatement->execute(
        array(
            ':title'=>$title,
            ':description'=>$desc

        )
    );
    if($result){
        echo "<script>alert('New Todo is added');window.location.href='index.php';</script>";
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
</head>
<body>
    <div class="card">
        <div class="card-body">
            <h2>Create New Todo</h2>
            <form class=""action="add.php" method="POST">
            <div class="form-group">
                <label for="">Title</label>
                <input type="text"class="form-control"name="title" value="" required>
            </div>
            <div class="form-group">
                <label for="">Description</label>
                <textarea type="text"class="form-control" name="description" value="" rows="8" cols="80"required></textarea>
            </div>
            <div class="form-group">
                <input type="submit"class="btn btn-primary" name=""value="Submit">
                <a href="index.php" class="btn btn-secondary">Back</a>
            </div>
            </form>
        </div>
    </div>
</body>
</html>